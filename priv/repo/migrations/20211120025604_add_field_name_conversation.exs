defmodule RikimaruChatApi.Repo.Migrations.AddFieldNameConversation do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :name,            :string
    end
  end
end
