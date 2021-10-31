defmodule RikimaruChatApi.Rikimaru.UserRelation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users_relations" do
    field :friend_id, :string
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(user_relation, attrs) do
    user_relation
    |> cast(attrs, [:id, :user_id, :friend_id])
    |> validate_required([:id, :user_id, :friend_id])
  end
end
