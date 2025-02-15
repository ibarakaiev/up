defmodule Up.Repo do
  use Ecto.Repo,
    otp_app: :up,
    adapter: Ecto.Adapters.Postgres
end
