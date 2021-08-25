defmodule Newsbloat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Newsbloat.Repo,
      # Start the Telemetry supervisor
      NewsbloatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Newsbloat.PubSub},
      # Start the Endpoint (http/https)
      NewsbloatWeb.Endpoint,
      # Start a worker by calling: Newsbloat.Worker.start_link(arg)
      # {Newsbloat.Worker, arg}
      {Newsbloat.Jobs.FetchNewFeedItems, name: NewsbloatWeb.Jobs.FetchNewFeedItems}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Newsbloat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NewsbloatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
