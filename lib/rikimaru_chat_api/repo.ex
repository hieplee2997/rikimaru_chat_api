defmodule RikimaruChatApi.Repo do
  use Ecto.Repo,
    otp_app: :rikimaru_chat_api,
    adapter: Ecto.Adapters.Postgres
end
