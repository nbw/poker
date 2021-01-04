defmodule PokerWeb.RoomChannel do
  use Phoenix.Channel

  alias PokerWeb.Presence #Added alias

  def join("room:" <> _uid, _message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_in("message:new", payload, socket) do
    broadcast! socket, "message:new", %{user: payload["user"],
      message: payload["message"]}
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    IO.puts("after join: ")
    name = socket.assigns.current_user
    {:ok, _} = Presence.track(socket, name, %{
      online_at: inspect(System.system_time(:seconds))
    })
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end
end
