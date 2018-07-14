defmodule StringUtil do
  def slice(str, start) do
    start_len =
      case start >= 0 do
        true -> start
        false -> String.length(str) - abs(start)
      end

    start_len =
      case start_len >= 0 do
        true -> start_len
        false -> 0
      end

    len = String.length(str) - start_len

    case len >= 0 do
      true -> String.slice(str, start_len, len)
      false -> ""
    end
  end

  def is_nil_or_empty(str) do
    str == nil || str == ""
  end
end
