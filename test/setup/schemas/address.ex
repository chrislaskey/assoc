defmodule Assoc.Test.Address do
  use Assoc.Test.Schema
  use Assoc.Schema, repo: Assoc.Test.Repo

  schema "addresses" do
    field(:address, :string)

    belongs_to(:user, Assoc.Test.User, on_replace: :update)

    timestamps()
  end

  def updatable_associations,
    do: [
      user: Assoc.Test.User
    ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:address])
    |> validate_required([:address])
  end
end
