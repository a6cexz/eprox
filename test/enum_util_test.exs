defmodule EnumUtilTest do
  use ExUnit.Case
  doctest EnumUtil

  test "map_while_with" do
    list = ["1", "2", "*", "3", "4"]
    mapped = EnumUtil.map_while_with(list, fn x -> x <> "_" end, fn x -> x != "*_" end)
    assert ["1_", "2_", "*_"] = mapped
  end
end
