defmodule PokerWeb.Router do
  use PokerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_user_token
  end

  defp put_user_token(conn, _) do
    token = Phoenix.Token.sign(conn, "user socket", UUID.uuid1(:hex))
    assign(conn, :user_token, token)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PokerWeb do
    pipe_through :browser

    get "/", PageController, :index

    resources "/rooms", RoomController, only: [:new, :show]
  end

  # Other scopes may use custom stacks.
  # scope "/api", PokerWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
    pipe_through :browser
    live_dashboard "/dashboard", metrics: PokerWeb.Telemetry
  end
  end
end
