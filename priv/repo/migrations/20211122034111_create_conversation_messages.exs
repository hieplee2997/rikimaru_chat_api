defmodule RikimaruChatApi.Repo.Migrations.CreateConversationMessages do
  use Ecto.Migration

  def change do
    create table(:conversation_messages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :message, :text, null: false
      add :user_id, :uuid, null: false
      add :conversation_id, :string, null: false
      add :current_time, :bigint
      add :main_id, :uuid, null: false

      timestamps()
    end
  end
end
