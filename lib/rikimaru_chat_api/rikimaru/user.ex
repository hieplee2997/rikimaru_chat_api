defmodule RikimaruChatApi.Rikimaru.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    field :account_id, Ecto.UUID
    field :avatar_url, :string
    field :full_name, :string
    field :password_hash, :string
    field :user_name, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:full_name, :user_name, :password_hash, :avatar_url, :account_id])
    |> validate_required([:full_name, :user_name, :password_hash, :avatar_url, :account_id])
  end
end
