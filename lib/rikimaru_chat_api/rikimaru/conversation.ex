defmodule RikimaruChatApi.Rikimaru.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "conversations" do
    field :name, :string
    field :last_user_send_message, Ecto.UUID
    field :type, :string
    field :update_by_message, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:id, :type, :last_user_send_message, :name, :update_by_message])
    |> validate_required([:id, :type, :last_user_send_message, :name, :update_by_message])
  end
end
