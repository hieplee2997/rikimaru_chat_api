defmodule RikimaruChatApi.Repo.Migrations.CreateConversationMembers do
  use Ecto.Migration

  def change do
    create table(:conversation_members, primary_key: false) do
      add :id, :uuid,   primary_key: true
      add :conversation_id, :uuid
      add :user_id, :uuid
      add :seen, :boolean, default: false, null: false
      add :new_message_count, :integer

      timestamps()
    end
  end
end
