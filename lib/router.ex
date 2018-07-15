defmodule Router do
  defp push_to_list(list, nil) do
    list
  end

  defp push_to_list(list, item) do
    list ++ [item]
  end

  def tokenize_route(route) do
    parts = String.split(route, "/")

    parts =
      if hd(parts) == "" do
        tl(parts)
      else
        parts
      end

    EnumUtil.map_while_with(parts, &part_to_token/1, &is_not_wildcard?/1)
  end

  def is_not_wildcard?(part) do
    !wildcard?(part)
  end

  def wildcard?({:wildcard, ""}) do
    true
  end

  def wildcard?(_) do
    false
  end

  def part_to_token("*") do
    {:wildcard, ""}
  end

  def part_to_token(part) do
    if String.first(part) == ":" do
      {:key, StringUtil.slice(part, 1)}
    else
      {:text, part}
    end
  end

  def extract_keys([], _) do
    %{}
  end

  def extract_keys(keys, parts) do
    Enum.reduce(keys, Map.new(), fn e, m ->
      Map.put(m, e.name, Enum.at(parts, e.index))
    end)
  end

  def update_parent_key(cnode, node) do
    key = nil

    key =
      if node[:withKey] != nil do
        node.withKey
      else
        if node[:_parentKey] != nil do
          node._parentKey
        else
          key
        end
      end

    if key != nil do
      put_in(cnode, [:_parentKey], key)
    else
      cnode
    end
  end

  def update_key_in_children(n) do
    if n == nil do
      nil
    else
      n =
        if n[:withKey] != nil and n[:_parentKey] != nil do
          n1 = put_in(n.withKey, [:_parentKey], n._parentKey)
          n1 = update_key_in_children(n1)
          put_in(n, [:withKey], n1)
        else
          n
        end

      n =
        if n[:text] != nil do
          new_text =
            Enum.map(n.text, fn {k, v} ->
              v = update_parent_key(v, n)
              v = update_key_in_children(v)
              {k, v}
            end)

          new_text = Enum.into(new_text, %{})
          put_in(n, [:text], new_text)
        else
          n
        end

      n
    end
  end

  def create_router() do
    %{
      isRouter: true,
      root: create_route_element(0)
    }
  end

  def create_route_element(index) do
    %{
      index: index,
      text: %{},
      _parentKey: nil,
      withKey: nil,
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }
  end

  def add_route_tokens(node, [], _, value, keys, _) do
    node = put_in(node, [:value], value)
    node = put_in(node, [:keys], keys)
    node = put_in(node, [:endpoint], true)
    node
  end

  def add_route_tokens(node, tokens, index, value, keys, parent_key_stack) do
    token = hd(tokens)
    {token_type, token_text} = token
    next_tokens = tl(tokens)

    case token_type do
      :text ->
        key = String.to_atom(token_text)
        next_node = node.text[key] || create_route_element(index + 1)

        update_router_node(node, next_node, next_tokens, index, value, keys, parent_key_stack, [
          :text,
          key
        ])

      :key ->
        next_node = node[:withKey] || create_route_element(index + 1)
        parent_key = List.last(parent_key_stack)
        parent_key_stack = List.delete(parent_key_stack, parent_key)
        keys = push_to_list(keys, %{name: token_text, index: index})

        update_router_node(node, next_node, next_tokens, index, value, keys, parent_key_stack, [
          :withKey
        ])

      :wildcard ->
        next_node = node[:wildcard] || create_route_element(index + 1)

        update_router_node(node, next_node, next_tokens, index, value, keys, parent_key_stack, [
          :wildcard
        ])
    end
  end

  defp update_router_node(
         node,
         next_node,
         next_tokens,
         index,
         value,
         keys,
         parent_key_stack,
         update_path
       ) do
    parent_key = List.last(parent_key_stack)
    next_node = put_in(next_node, [:_parentKey], parent_key)
    next_node = update_key_in_children(next_node)

    parent_key_stack = push_to_list(parent_key_stack, node[:withKey])
    next_node = add_route_tokens(next_node, next_tokens, index + 1, value, keys, parent_key_stack)

    node = put_in(node, update_path, next_node)
    node
  end

  def add_route(router, nil, _) do
    router
  end

  def add_route(router, route, value) do
    tokens = tokenize_route(route)
    root = router.root
    keys = []
    parent_key_stack = []
    root = add_route_tokens(root, tokens, 0, value, keys, parent_key_stack)
    router = put_in(router, [:root], root)
    router
  end

  defp walk_nodes(node, parts_map, len, last_wildcard) do
    if node && node.index < len do
      last_wildcard =
        if node.wildcard && (!last_wildcard || last_wildcard.index < node.wildcard.index) do
          node.wildcard
        else
          last_wildcard
        end

      part = parts_map[node.index]
      key = String.to_atom(part)
      next_node = node.text[key] || node.withKey || node._parentKey

      walk_nodes(next_node, parts_map, len, last_wildcard)
    else
      {node, last_wildcard}
    end
  end

  def parse_url_string(router, pathname, search) do
    parts = String.split(pathname, "/")

    parts =
      if hd(parts) === "" do
        tl(parts)
      else
        parts
      end

    parts_map =
      parts
      |> Enum.with_index()
      |> Enum.map(fn {a, b} -> {b, a} end)
      |> Enum.into(%{})

    len = length(parts)

    last_wildcard = nil
    {node, last_wildcard} = walk_nodes(router.root, parts_map, len, last_wildcard)

    node =
      if node && !node.endpoint do
        nil
      else
        node
      end

    value = nil
    keys = nil
    wildcard_extra = nil

    wildcard_extra =
      if !node && last_wildcard do
        parts
        |> Enum.slice(last_wildcard.index - 1, len)
        |> Enum.join("/")
      else
        wildcard_extra
      end

    node =
      if !node && last_wildcard do
        last_wildcard
      else
        node
      end

    value =
      if node do
        node.value
      else
        value
      end

    keys =
      if node do
        extract_keys(node.keys, parts)
      else
        keys
      end

    wildcard_extra =
      if wildcard_extra && search do
        wildcard_extra <> search
      else
        wildcard_extra
      end

    %{
      value: value,
      parts: parts,
      keys: keys,
      extra: wildcard_extra
    }
  end

  def parse_url(urlString) do
    uri = URI.parse(urlString)

    search =
      case uri.query do
        nil -> ""
        query -> "?" <> query
      end

    %{pathname: uri.path, search: search}
  end

  def parse(router, urlString) do
    url = parse_url(urlString)
    result = parse_url_string(router, url.pathname, url.search)
    Map.put(result, :url, url)
  end
end
