defmodule RikimaruChatApi.Rikimaru.ConversationMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "conversation_members" do
    field :conversation_id, :string
    field :new_message_count, :integer
    field :seen, :boolean, default: false
    field :user_id, Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(conversation_member, attrs) do
    conversation_member
    |> cast(attrs, [:id, :conversation_id, :user_id, :seen, :new_message_count])
    |> validate_required([:id, :conversation_id, :user_id, :seen, :new_message_count])
  end
end
