defmodule RikimaruChatApiWeb.ConversationController do
    import Ecto.Query
    use RikimaruChatApiWeb, :controller
    alias RikimaruChatApi.Rikimaru.{User, Tools, UserRelation, Conversation, ConversationMember}
    alias RikimaruChatApi.{Repo}

    plug Rikimaru.API.Plugs.Auth
    def get_list_conversation(conn, _) do
        user_id = conn.assigns.current_user.uid
        

    end
    def create_conversation(conn, params) do
        user_id = conn.assigns.current_user.uid
        friend_id = params["friend_id"]

        if friend_id do
            is_not_friend = from(
                u in UserRelation,
                join: ur in UserRelation,
                on: ur.user_id == u.friend_id and ur.friend_id == u.user_id,
                where: u.user_id == ^user_id and u.friend_id == ^friend_id,
                limit: 1,
                offset: 0,
                select: u.friend_id
              ) |> Repo.all |> Enum.empty?()
            if is_not_friend do
              json conn, %{success: false, message: "Tài khoản này không phải bạn bè"}
            else
                id = Ecto.UUID.generate
                type = "direct"
                %Conversation{
                    type: type
                }
                |> Repo.insert!
                data = [%{
                    conversation_id: id,
                    user_id: user_id,
                    seen: true,
                    new_message_count: 0,
                    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                }, %{
                    conversation_id: id,
                    user_id: friend_id,
                    seen: false,
                    new_message_count: 1,
                    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                }]
                Repo.insert_all(ConversationMember, data, returning: true)
                |> case  do
                    {0, _} -> json conn, %{success: false, message: "Lỗi khi insert"}
                    {_, data} -> 
                        IO.inspect data, label: "data member inserted"
                        json conn, %{success: true}
                end
            end
        end
    end
end