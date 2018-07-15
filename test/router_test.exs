defmodule RouterTest do
  use ExUnit.Case
  doctest Router

  test "Should have tokenizeRoute function" do
    assert Router.tokenize_route("") == []
  end

  test "tokenize_route" do
    assert Router.tokenize_route("") == []

    assert Router.tokenize_route("/") == [{:text, ""}]
    assert Router.tokenize_route("test") == [{:text, "test"}]
    assert Router.tokenize_route("/test") == [{:text, "test"}]
    assert Router.tokenize_route("test/") == [{:text, "test"}, {:text, ""}]
    assert Router.tokenize_route("p1/p2") == [{:text, "p1"}, {:text, "p2"}]
    assert Router.tokenize_route("/p1/p2") == [{:text, "p1"}, {:text, "p2"}]

    assert Router.tokenize_route("*") == [{:wildcard, ""}]
    assert Router.tokenize_route("/*") == [{:wildcard, ""}]
    assert Router.tokenize_route("p1/*") == [{:text, "p1"}, {:wildcard, ""}]
    assert Router.tokenize_route("/p1/p2/*") == [{:text, "p1"}, {:text, "p2"}, {:wildcard, ""}]
    assert Router.tokenize_route("/p1/p2/*/p3") == [{:text, "p1"}, {:text, "p2"}, {:wildcard, ""}]

    assert Router.tokenize_route("/p1/p2/*/p3/p4") == [
             {:text, "p1"},
             {:text, "p2"},
             {:wildcard, ""}
           ]

    assert Router.tokenize_route(":k1") == [{:key, "k1"}]
    assert Router.tokenize_route("/:k1") == [{:key, "k1"}]
    assert Router.tokenize_route(":k1/:k2") == [{:key, "k1"}, {:key, "k2"}]
    assert Router.tokenize_route("/:k1/:k2") == [{:key, "k1"}, {:key, "k2"}]

    assert Router.tokenize_route("/:k1/:k2/p1/:k3") == [
             {:key, "k1"},
             {:key, "k2"},
             {:text, "p1"},
             {:key, "k3"}
           ]

    assert Router.tokenize_route("/p1/p2/:k1/p3/*/p4") == [
             {:text, "p1"},
             {:text, "p2"},
             {:key, "k1"},
             {:text, "p3"},
             {:wildcard, ""}
           ]
  end

  test "part_to_token" do
    assert Router.part_to_token("") == {:text, ""}
    assert Router.part_to_token(":k") == {:key, "k"}
    assert Router.part_to_token("test") == {:text, "test"}
    assert Router.part_to_token("*") == {:wildcard, ""}
  end

  test "wildcard?" do
    assert Router.wildcard?({:text, ""}) == false
    assert Router.wildcard?({:wildcard, ""}) == true
  end

  test "is_not_wildcard?" do
    assert Router.is_not_wildcard?({:text, ""}) == true
    assert Router.is_not_wildcard?({:wildcard, ""}) == false
  end

  test "extract_keys" do
    assert Router.extract_keys([], []) == %{}
    assert Router.extract_keys([], ["p1"]) == %{}
    assert Router.extract_keys([%{name: "n1", index: 0}], ["p1"]) == %{"n1" => "p1"}

    assert Router.extract_keys([%{name: "n1", index: 0}, %{name: "n2", index: 1}], ["p1", "p2"]) ==
             %{"n1" => "p1", "n2" => "p2"}

    assert Router.extract_keys([%{name: "n1", index: 1}, %{name: "n2", index: 0}], ["p1", "p2"]) ==
             %{"n1" => "p2", "n2" => "p1"}
  end

  test "update_key_in_children" do
    assert Router.update_key_in_children(%{}) == %{}
  end

  test "update_key_in_children nil" do
    assert Router.update_key_in_children(nil) == nil
  end

  test "updateKeyInChildren on node with key 1" do
    node = %{withKey: %{}}
    expected = %{withKey: %{}}
    node = Router.update_key_in_children(node)
    assert node == expected
  end

  test "updateKeyInChildren on node with key 2" do
    node = %{_parentKey: "k1", withKey: %{}}
    expected = %{_parentKey: "k1", withKey: %{_parentKey: "k1"}}
    node = Router.update_key_in_children(node)
    assert node == expected
  end

  test "updateKeyInChildren on node with key 3" do
    node = %{_parentKey: "k1", withKey: %{withKey: %{}}}
    expected = %{_parentKey: "k1", withKey: %{withKey: %{_parentKey: "k1"}, _parentKey: "k1"}}
    node = Router.update_key_in_children(node)
    assert node == expected
  end

  test "updateKeyInChildren on node with key and text 1" do
    node = %{text: %{n1: %{}, n2: %{}, n3: %{}}, withKey: %{test: "test"}, _parentKey: "k1"}

    expected = %{
      text: %{
        n1: %{_parentKey: %{test: "test", _parentKey: "k1"}},
        n2: %{_parentKey: %{test: "test", _parentKey: "k1"}},
        n3: %{_parentKey: %{test: "test", _parentKey: "k1"}}
      },
      withKey: %{test: "test", _parentKey: "k1"},
      _parentKey: "k1"
    }

    node = Router.update_key_in_children(node)
    assert node == expected
  end

  test "updateKeyInChildren on node with key and text 2" do
    node = %{text: %{n1: %{}, n2: %{}, n3: %{}}, _parentKey: "k1"}

    expected = %{
      text: %{n1: %{_parentKey: "k1"}, n2: %{_parentKey: "k1"}, n3: %{_parentKey: "k1"}},
      _parentKey: "k1"
    }

    node = Router.update_key_in_children(node)
    assert node == expected
  end

  test "updateKeyInChildren on node with key and text 3" do
    node = %{text: %{n1: %{text: %{n1: %{}}}}, _parentKey: "k1"}

    expected = %{
      text: %{n1: %{text: %{n1: %{_parentKey: "k1"}}, _parentKey: "k1"}},
      _parentKey: "k1"
    }

    node = Router.update_key_in_children(node)
    assert node == expected
  end

  test "updateKeyInChildren on node with key and text 4" do
    node = %{text: %{n1: %{text: %{n1: %{}}}}, withKey: %{test: "test"}}

    expected = %{
      text: %{n1: %{text: %{n1: %{_parentKey: %{test: "test"}}}, _parentKey: %{test: "test"}}},
      withKey: %{test: "test"}
    }

    node = Router.update_key_in_children(node)
    assert node == expected
  end

  test "updateKeyInChildren on node with key and text 5" do
    node = %{text: %{n1: %{text: %{n2: %{text: %{n3: %{}}}}, withKey: %{test: 'test'}}}}

    expected = %{
      text: %{
        n1: %{
          text: %{n2: %{text: %{n3: %{_parentKey: %{test: 'test'}}}, _parentKey: %{test: 'test'}}},
          withKey: %{test: 'test'}
        }
      }
    }

    node = Router.update_key_in_children(node)
    assert node == expected
  end

  test "create_router function" do
    router = Router.create_router()

    expected = %{
      isRouter: true,
      root: %{
        index: 0,
        text: %{},
        _parentKey: nil,
        withKey: nil,
        wildcard: nil,
        value: nil,
        keys: [],
        endpoint: false
      }
    }

    assert router == expected
  end

  test "Should have add_route function" do
    router = Router.create_router()
    router = Router.add_route(router, nil, "v1")

    expected = %{
      index: 0,
      text: %{},
      _parentKey: nil,
      withKey: nil,
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute empty" do
    router = Router.create_router()
    router = Router.add_route(router, "", "v1")

    expected = %{
      index: 0,
      text: %{},
      _parentKey: nil,
      withKey: nil,
      wildcard: nil,
      value: "v1",
      keys: [],
      endpoint: true
    }

    assert router.root == expected
  end

  test "Test addRoute /" do
    router = Router.create_router()
    router = Router.add_route(router, "/", "v1")

    expected = %{
      index: 0,
      text: %{
        "": %{
          index: 1,
          text: %{},
          _parentKey: nil,
          withKey: nil,
          wildcard: nil,
          value: "v1",
          keys: [],
          endpoint: true
        }
      },
      _parentKey: nil,
      withKey: nil,
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute /p1" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1", "v1")

    expected = %{
      index: 0,
      text: %{
        p1: %{
          index: 1,
          text: %{},
          _parentKey: nil,
          withKey: nil,
          wildcard: nil,
          value: "v1",
          keys: [],
          endpoint: true
        }
      },
      _parentKey: nil,
      withKey: nil,
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute /p1/" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/", "v1")

    expected = %{
      index: 0,
      text: %{
        p1: %{
          index: 1,
          text: %{
            "": %{
              index: 2,
              text: %{},
              _parentKey: nil,
              withKey: nil,
              wildcard: nil,
              value: "v1",
              keys: [],
              endpoint: true
            }
          },
          _parentKey: nil,
          withKey: nil,
          wildcard: nil,
          value: nil,
          keys: [],
          endpoint: false
        }
      },
      _parentKey: nil,
      withKey: nil,
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute /p1/p2" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/p2", "v1")

    expected = %{
      index: 0,
      text: %{
        p1: %{
          index: 1,
          text: %{
            p2: %{
              index: 2,
              text: %{},
              _parentKey: nil,
              withKey: nil,
              wildcard: nil,
              value: "v1",
              keys: [],
              endpoint: true
            }
          },
          _parentKey: nil,
          withKey: nil,
          wildcard: nil,
          value: nil,
          keys: [],
          endpoint: false
        }
      },
      _parentKey: nil,
      withKey: nil,
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute /:k1" do
    router = Router.create_router()
    router = Router.add_route(router, "/:k1", "v1")

    expected = %{
      index: 0,
      text: %{},
      _parentKey: nil,
      withKey: %{
        index: 1,
        text: %{},
        _parentKey: nil,
        withKey: nil,
        wildcard: nil,
        value: "v1",
        keys: [%{name: "k1", index: 0}],
        endpoint: true
      },
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute /:k1/" do
    router = Router.create_router()
    router = Router.add_route(router, "/:k1/", "v1")

    expected = %{
      index: 0,
      text: %{},
      _parentKey: nil,
      withKey: %{
        index: 1,
        text: %{
          "": %{
            index: 2,
            text: %{},
            _parentKey: nil,
            withKey: nil,
            wildcard: nil,
            value: "v1",
            keys: [%{name: "k1", index: 0}],
            endpoint: true
          }
        },
        _parentKey: nil,
        withKey: nil,
        wildcard: nil,
        value: nil,
        keys: [],
        endpoint: false
      },
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute /:k1/:k2" do
    router = Router.create_router()
    router = Router.add_route(router, "/:k1/:k2", "v1")

    expected = %{
      index: 0,
      text: %{},
      _parentKey: nil,
      withKey: %{
        index: 1,
        text: %{},
        _parentKey: nil,
        withKey: %{
          index: 2,
          text: %{},
          _parentKey: nil,
          withKey: nil,
          wildcard: nil,
          value: "v1",
          keys: [%{name: "k1", index: 0}, %{name: "k2", index: 1}],
          endpoint: true
        },
        wildcard: nil,
        value: nil,
        keys: [],
        endpoint: false
      },
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute /*" do
    router = Router.create_router()
    router = Router.add_route(router, "/*", "v1")

    expected = %{
      index: 0,
      text: %{},
      _parentKey: nil,
      withKey: nil,
      wildcard: %{
        index: 1,
        text: %{},
        _parentKey: nil,
        withKey: nil,
        wildcard: nil,
        value: "v1",
        keys: [],
        endpoint: true
      },
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test addRoute /p1/:k1/*" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/:k1/*", "v1")

    expected = %{
      index: 0,
      text: %{
        p1: %{
          index: 1,
          text: %{},
          _parentKey: nil,
          withKey: %{
            index: 2,
            text: %{},
            _parentKey: nil,
            withKey: nil,
            wildcard: %{
              index: 3,
              text: %{},
              _parentKey: nil,
              withKey: nil,
              wildcard: nil,
              value: "v1",
              keys: [%{name: "k1", index: 1}],
              endpoint: true
            },
            value: nil,
            keys: [],
            endpoint: false
          },
          wildcard: nil,
          value: nil,
          keys: [],
          endpoint: false
        }
      },
      _parentKey: nil,
      withKey: nil,
      wildcard: nil,
      value: nil,
      keys: [],
      endpoint: false
    }

    assert router.root == expected
  end

  test "Test parse_url_string empty" do
    router = Router.create_router()
    result = Router.parse_url_string(router, "", "")

    expected = %{value: nil, parts: [], keys: nil, extra: nil}

    assert result == expected
  end

  test "Test parse_url_string /" do
    router = Router.create_router()
    result = Router.parse_url_string(router, "/", "")

    expected = %{
      value: nil,
      parts: [""],
      keys: nil,
      extra: nil
    }

    assert result == expected
  end

  test "Test parse_url_string /p1" do
    router = Router.create_router()
    result = Router.parse_url_string(router, "/p1", "")

    expected = %{
      value: nil,
      parts: ["p1"],
      keys: nil,
      extra: nil
    }

    assert result == expected
  end

  test "Test parse_url_string /p1/p2" do
    router = Router.create_router()
    result = Router.parse_url_string(router, "/p1/p2", "")

    expected = %{
      value: nil,
      parts: ["p1", "p2"],
      keys: nil,
      extra: nil
    }

    assert result == expected
  end

  test "Test parse_url_string /p1 with routes" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/p2", "v")
    result = Router.parse_url_string(router, "/p1", "")

    expected = %{
      value: nil,
      parts: ["p1"],
      keys: nil,
      extra: nil
    }

    assert result == expected
  end

  test "Test parse_url_string /p1/p2 with routes" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/p2", "v")
    result = Router.parse_url_string(router, "/p1/p2", "")

    expected = %{
      value: "v",
      parts: ["p1", "p2"],
      keys: %{},
      extra: nil
    }

    assert result == expected
  end

  test "Test parse_url_string /p1/p2 with routes and search" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/p2", "v")
    result = Router.parse_url_string(router, "/p1/p2", "s1")

    expected = %{
      value: "v",
      parts: ["p1", "p2"],
      keys: %{},
      extra: nil
    }

    assert result == expected
  end

  test "Test parse_url_string /p1/p2/p3 with wildcard" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/p2/*", "v")
    result = Router.parse_url_string(router, "/p1/p2/p3", "")

    expected = %{
      value: "v",
      parts: ["p1", "p2", "p3"],
      keys: %{},
      extra: "p3"
    }

    assert result == expected
  end

  test "Test parse_url_string /p1/p2/p3 with wildcard and search" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/p2/*", "v")
    result = Router.parse_url_string(router, "/p1/p2/p3", "s1")

    expected = %{
      value: "v",
      parts: ["p1", "p2", "p3"],
      keys: %{},
      extra: "p3s1"
    }

    assert result == expected
  end

  test "Test parse_url_string /p1/p2/p3 with key" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/p2/:k1", "v")
    result = Router.parse_url_string(router, "/p1/p2/p3", "")

    expected = %{
      value: "v",
      parts: ["p1", "p2", "p3"],
      keys: %{"k1" => "p3"},
      extra: nil
    }

    assert result == expected
  end

  test "Test parse_url_string /p1/p2/p3 with 2 keys" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/p2/:k1/p3/:k2", "v")
    result = Router.parse_url_string(router, "/p1/p2/kv1/p3/kv2", "")

    expected = %{
      value: "v",
      parts: ["p1", "p2", "kv1", "p3", "kv2"],
      keys: %{"k1" => "kv1", "k2" => "kv2"},
      extra: nil
    }

    assert result == expected
  end

  test "Should have parseUrl function" do
    result = Router.parse_url("")
    assert result != nil
  end

  test "Test parseUrl empty string" do
    result = Router.parse_url("")
    assert Map.has_key?(result, :pathname)
    assert Map.has_key?(result, :search)
  end

  test "Test parseUrl p1" do
    result = Router.parse_url("p1")
    assert result.pathname == "p1"
    assert result.search == ""
  end

  test "Test parseUrl p1?s1" do
    result = Router.parse_url("p1?s1")
    assert result.pathname == "p1"
    assert result.search == "?s1"
  end

  test "Test parseUrl /p1/p2/p3?k1=v1&k2=v2" do
    result = Router.parse_url("/p1/p2/p3?k1=v1&k2=v2")
    assert result.pathname == "/p1/p2/p3"
    assert result.search == "?k1=v1&k2=v2"
  end

  test "Test parse /p1/* and ?k1=v1&k2=v2" do
    router = Router.create_router()
    router = Router.add_route(router, "/p1/*", "v")
    result = Router.parse(router, "/p1/p2?k1=v1&k2=v2")

    expected = %{
      value: "v",
      parts: ["p1", "p2"],
      keys: %{},
      extra: "p2?k1=v1&k2=v2",
      url: %{
        pathname: "/p1/p2",
        search: "?k1=v1&k2=v2"
      }
    }

    assert result == expected
  end
end
