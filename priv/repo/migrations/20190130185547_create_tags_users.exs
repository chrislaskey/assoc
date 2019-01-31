defmodule Assoc.Test.Repo.Migrations.CreateTagsUsers do
  use Ecto.Migration

  def change do
    create table(:tags_users) do
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create unique_index(:tags_users, [:tag_id, :user_id])
  end
end
