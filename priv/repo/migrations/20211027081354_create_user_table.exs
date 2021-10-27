defmodule RikimaruChatApi.Repo.Migrations.CreateUserTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id,        :uuid, primary_key: true
      add :full_name, :string
      add :user_name, :string
      add :password_hash, :string
      add :avatar_url, :string
      add :account_id, :uuid

      timestamps()
    end
  end
end
