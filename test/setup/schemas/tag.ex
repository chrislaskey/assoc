defmodule Assoc.Test.Tag do
  use Assoc.Test.Schema

  schema "tags" do
    field(:name, :string)

    many_to_many(:users, Assoc.Test.User, join_through: "tags_users", on_replace: :delete)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
