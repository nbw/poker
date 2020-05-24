defmodule Poker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Poker.Repo,
      # Start the Telemetry supervisor
      PokerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Poker.PubSub},
      # Start the Endpoint (http/https)
      PokerWeb.Endpoint,
      # Start a worker by calling: Poker.Worker.start_link(arg)
      # {Poker.Worker, arg}
      PokerWeb.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Poker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PokerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
