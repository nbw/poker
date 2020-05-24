defmodule PokerWeb.RoomView do
  use PokerWeb, :view

  require Integer

  defdelegate odd, to: Integer, as: :odd
  defdelegate even, to: Integer, as: :even

  @doc """
   A user is considered joined if they have a name
  """
  def joined?(nil), do: false
  def joined?(%{name: ""}), do: false
  def joined?(%{name: _name}), do: true

  @doc """
   Returns the max score and a Map with of all tallied scores
  """
  def scores(users) do
    scores = users
    |> Enum.filter(fn u -> u[:score] > 0 end)
    |> Enum.reduce(%{}, fn u, s ->
      {_, s_new} = Map.get_and_update(s, u[:score],
        fn current_value ->
          case current_value do
            nil -> {current_value, 1}
            _ -> {current_value, current_value + 1}
          end
        end)

        s_new
    end)

    max_score = Map.values(scores)
                |> case do
                  [] -> -1
                  v -> Enum.max(v)
                end

    {max_score, scores}
  end

  @doc """
   Number of particpants who've chosen a card
  """
  def participants(users) do
    answered = Enum.count(users, fn u -> u[:score] >= 0 end)
    total = length(users)
    "#{answered} / #{total}"
  end
end
