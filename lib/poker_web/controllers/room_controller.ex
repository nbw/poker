defmodule PokerWeb.RoomController do
  use PokerWeb, :controller

  import Phoenix.LiveView.Controller

  alias PokerWeb.RoomLiveView

  alias Poker.Room.Auth

  def show(conn, %{"id"=> id}) do
    # conn
    # |> assign(:room_id, id)
    # |> render("show.html")
    conn
    |> live_render(RoomLiveView, session:
      %{
        "room_id" => id,
        "user_token" => conn.assigns.user_token
      })
  end

  def show(conn, _), do: redirect(conn, to: "/")

  def new(conn, _params) do
    conn
    |> redirect(to: Routes.room_path(conn, :show, Auth.generate_token(12)))
  end
end
