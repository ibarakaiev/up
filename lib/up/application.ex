defmodule Up.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      UpWeb.Telemetry,
      Up.Repo,
      {DNSCluster, query: Application.get_env(:up, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Up.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Up.Finch},
      # Start a worker by calling: Up.Worker.start_link(arg)
      # {Up.Worker, arg},
      # Start to serve requests, typically the last entry
      UpWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Up.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    UpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
