defmodule StringUtilTest do
  use ExUnit.Case
  doctest StringUtil

  test "slice string" do
    assert StringUtil.slice("", 0) == ""
    assert StringUtil.slice("", 1) == ""
    assert StringUtil.slice("", 2) == ""
    assert StringUtil.slice("", 3) == ""

    assert StringUtil.slice("", -1) == ""
    assert StringUtil.slice("", -2) == ""
    assert StringUtil.slice("", -3) == ""

    assert StringUtil.slice("a", 0) == "a"
    assert StringUtil.slice("a", 1) == ""
    assert StringUtil.slice("a", 2) == ""
    assert StringUtil.slice("a", 3) == ""

    assert StringUtil.slice("a", -1) == "a"
    assert StringUtil.slice("a", -2) == "a"
    assert StringUtil.slice("a", -3) == "a"
  end

  test "is_nil_or_empty" do
    assert true == StringUtil.is_nil_or_empty(nil)
    assert true == StringUtil.is_nil_or_empty("")
    assert false == StringUtil.is_nil_or_empty("a")
    assert false == StringUtil.is_nil_or_empty(10)
  end
end
