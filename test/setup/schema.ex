defmodule Assoc.Test.Schema do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias __MODULE__
      alias Assoc.Test.Repo
      alias Assoc.Test.Schema
    end
  end
end
