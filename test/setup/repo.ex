defmodule Assoc.Test.Repo do
  use Ecto.Repo,
    otp_app: :assoc,
    adapter: Ecto.Adapters.Postgres
end
