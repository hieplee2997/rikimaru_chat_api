defmodule RikimaruChatApi.Repo.Migrations.CreateUsersRelations do
  use Ecto.Migration

  def change do
    create table(:users_relations, primary_key: false) do
      add :id, :uuid,               primary_key: true
      add :user_id, :string
      add :friend_id, :string

      timestamps()
    end
  end
end
