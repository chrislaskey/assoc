defmodule Assoc.Test.Role do
  use Assoc.Test.Schema

  schema "roles" do
    field :name, :string

    has_many :user_roles, Assoc.Test.UserRole, on_delete: :delete_all, on_replace: :delete
    has_many :users, through: [:user_roles, :user]

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
