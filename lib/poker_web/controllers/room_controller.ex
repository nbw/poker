defmodule PokerWeb.RoomController do
  use PokerWeb, :controller

  import Phoenix.LiveView.Controller

  alias PokerWeb.RoomLiveView

  alias Poker.Room.Auth

  def show(conn, %{"id"=> id}) do
    conn
    |> live_render(RoomLiveView, session:
      %{
        "room_id" => id,
        "user_token" => conn.assigns.user_token,
        "locale" => get_session(conn, :locale)
      })
  end

  def index(conn, _), do: redirect(conn, to: "/")

  def new(conn, _), do: render(conn, "new.html")

  def create(conn, %{"room_name" => room_name}) do
    redirect(conn, to: Routes.room_path(conn, :show, underscore(room_name)))
  end

  def create(conn, _) do
    redirect(conn, to: Routes.room_path(conn, :show, Auth.generate_token(12)))
  end

  defp underscore(s) do
    s
    |> String.trim()
    |> String.replace(~r/\s+/, "_")
  end
end
