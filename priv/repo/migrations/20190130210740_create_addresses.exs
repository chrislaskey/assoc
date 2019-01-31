defmodule Assoc.Test.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :address, :string
      add :user_id, references(:users, on_delete: :delete_all)
      timestamps()
    end
  end
end
