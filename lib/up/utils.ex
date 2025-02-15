defmodule Up.Utils do
  @moduledoc false

  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> binary_part(0, length)
    |> String.downcase()
  end
end
