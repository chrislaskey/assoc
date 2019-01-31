defmodule Assoc.Test.User do
  use Assoc.Test.Schema
  use Assoc.Schema, repo: Assoc.Test.Repo

  schema "users" do
    field :email, :string
    field :name, :string

    has_many :addresses, Assoc.Test.Address, on_delete: :delete_all, on_replace: :delete
    has_many :user_roles, Assoc.Test.UserRole, on_delete: :delete_all, on_replace: :delete
    has_many :roles, through: [:user_roles, :role]

    many_to_many :tags, Assoc.Test.Tag, join_through: "tags_users", on_replace: :delete

    timestamps()
  end

  def updatable_associations, do: [
    addresses: Assoc.Test.Address,
    tags: Assoc.Test.Tag,
    user_roles: Assoc.Test.UserRole
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :name])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end
end
