defmodule RikimaruChatApi.Rikimaru.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "conversations" do
    field :last_user_send_message, Ecto.UUID
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:id, :type, :last_user_send_message])
    |> validate_required([:id, :type, :last_user_send_message])
  end
end
