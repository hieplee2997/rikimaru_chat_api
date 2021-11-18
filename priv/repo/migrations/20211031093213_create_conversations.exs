defmodule RikimaruChatApi.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :uuid,   primary_key: true
      add :type, :string
      add :last_user_send_message, :uuid

      timestamps()
    end
  end
end
