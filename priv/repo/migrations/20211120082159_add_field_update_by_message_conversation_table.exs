defmodule RikimaruChatApi.Repo.Migrations.AddFieldUpdateByMessageConversationTable do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :update_by_message, :bigint
    end
  end
end
