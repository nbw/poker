defmodule Poker.Room.Auth do
  def generate_token(length \\ -1, format \\ :hex) do
    UUID.uuid1(format)
    |> String.slice(Range.new(0,length))
  end
end
