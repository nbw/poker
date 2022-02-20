defmodule PokerWeb.PageControllerTest do
  use PokerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Agile Poker"
  end
end
