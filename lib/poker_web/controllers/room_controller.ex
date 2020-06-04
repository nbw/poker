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
        "user_token" => conn.assigns.user_token
      })
  end

  def show(conn, _), do: redirect(conn, to: "/")

  def new(conn, _), do: render(conn, "new.html")

  def create(conn, %{"room_name" => room_name}) do
    redirect(conn, to: Routes.room_path(conn, :show, room_name))
  end

  def create(conn, _) do
    redirect(conn, to: Routes.room_path(conn, :show, Auth.generate_token(12)))
  end
end
