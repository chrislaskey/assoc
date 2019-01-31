defmodule Assoc.Test.UserRole do
  use Assoc.Test.Schema

  schema "user_roles" do
    belongs_to :created_by, Assoc.Test.User, foreign_key: :created_by_id, on_replace: :delete
    belongs_to :role, Assoc.Test.Role, on_replace: :delete
    belongs_to :user, Assoc.Test.User, on_replace: :delete

    timestamps()
  end

  # Callbacks

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:created_by_id, :role_id, :user_id])
    |> validate_required([:created_by_id, :role_id, :user_id])
    |> foreign_key_constraint(:created_by)
    |> foreign_key_constraint(:role_id)
    |> foreign_key_constraint(:user_id)
  end
end
