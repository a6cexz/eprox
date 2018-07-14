defmodule EnumUtil do
  def map_while_with(list, mapfunc, predicate) do
    Enum.reduce_while(list, [], fn el, acc ->
      mapped = mapfunc.(el)

      if predicate.(mapped) do
        {:cont, acc ++ [mapped]}
      else
        {:halt, acc ++ [mapped]}
      end
    end)
  end
end
