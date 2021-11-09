defmodule Assoc.Test.Application do
  @moduledoc """
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {Assoc.Test.Repo, []}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
