defmodule RikimaruChatApi.Rikimaru.ConversationMessage do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "conversation_messages" do
    field :message, :string
    field :user_id, Ecto.UUID
    field :conversation_id, :string
    field :current_time, :integer
    field :main_id, Ecto.UUID
    timestamps()
  end

  @doc false
  def changeset(conversation_message, attrs) do
    conversation_message
    |> cast(attrs, [:id, :message, :user_id, :conversation_id, :current_time, :main_id])
    |> validate_required([])
  end
end
