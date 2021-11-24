defmodule RikimaruChatApiWeb.ConversationController do
    import Ecto.Query
    use RikimaruChatApiWeb, :controller
    alias RikimaruChatApi.Rikimaru.{User, UserRelation, Conversation, ConversationMember, ConversationMessage}
    alias RikimaruChatApi.{Repo}
    alias RikimaruChatApiWeb.{Endpoint}

    plug Rikimaru.API.Plugs.Auth

    def index(conn, _) do
        user_id = conn.assigns.current_user.uid
        data = get_list_conversation(user_id)
        json conn, data
    end

    @spec get_list_conversation(any) :: %{data: list, success: boolean}
    def get_list_conversation(user_id) do
        case Ecto.UUID.dump(user_id) do
            {:ok, uuid_user} ->
                data = from(u in User,
                    join: cm in ConversationMember,
                    on: u.id == cm.user_id,
                    where: cm.conversation_id in fragment(
                        "(SELECT cm.conversation_id from conversation_members cm where cm.user_id = ?)",
                        ^uuid_user
                    ),
                    select: %{
                        "full_name" => u.full_name,
                        "user_name" => u.user_name,
                        "user_id" => u.id,
                        "avatar_url" => u.avatar_url,
                        "conversation_id" => cm.conversation_id
                    }
                ) |> Repo.all()
                all_conversation_id = Enum.uniq(Enum.map(data, fn x -> x["conversation_id"] end))
                data_conversation = from(c in Conversation,
                    where: c.id in ^all_conversation_id,
                    select: %{
                        "type" => c.type,
                        "id" => c.id,
                        "last_user_send_message" => c.last_user_send_message,
                        "update_by_message" => c.update_by_message,
                        "inserted_at" => c.inserted_at
                    }
                ) |> Repo.all()

                result = Enum.map(all_conversation_id, fn conversation_id ->
                    users = Enum.filter(data, fn user -> user["conversation_id"] == conversation_id end)
                            |> Enum.uniq_by(fn x -> x["user_id"] end)
                    conversation = Enum.filter(data_conversation, fn c -> c["id"] == conversation_id end) |> Enum.at(0)
                    %{
                        "users" => users,
                        "type" => conversation["type"],
                        "inserted_at" => conversation["inserted_at"],
                        "update_by_message" => conversation["update_by_message"] || 0,
                        "conversation_id" => conversation["id"]
                    }
                end)
                |> Enum.filter(fn c -> c != nil end)
                |> Enum.sort(fn (a,b) -> a["update_by_message"] > b["update_by_message"] end)
                |> Enum.filter(fn c -> c["conversation_id"] != nil end)
                %{data: result, success: true}
            _ ->
                %{data: [], success: false}
        end
    end

    def get_message_conversation(conn, params) do
        conversation_id = params["conversation_id"]

        messages = from(cms in ConversationMessage,
            where: cms.conversation_id == ^conversation_id,
            order_by: [desc: cms.current_time],
            limit: 20
        ) |> Repo.all
        |> Enum.map(fn m ->
           m |> Map.take([:message, :user_id, :current_time, :main_id])
        end)
        |> Enum.map(fn m ->
           %{
               "message" => m.message,
               "user_id" => m.user_id,
               "current_time" => m.current_time,
               "id" => m.main_id
            }
        end)
        json conn, %{success: true, data: %{"conversation_id" => conversation_id, "messages" => messages}}
    end

    def load_more_message(conn, params) do
        conversation_id = params["conversation_id"]
        last_id = params["last_id"]

        last_message = Repo.get_by(ConversationMessage, %{main_id: last_id, conversation_id: conversation_id})
        IO.inspect last_message.message
        if last_message do
            current_time_last_message = last_message.current_time
            messages = from(cms in ConversationMessage,
                where: cms.conversation_id == ^conversation_id and cms.current_time < ^current_time_last_message,
                order_by: [desc: cms.current_time],
                limit: 20
            ) |> Repo.all
            |> Enum.map(fn m ->
                m |> Map.take([:message, :user_id, :current_time, :main_id])
            end)
            |> Enum.map(fn m ->
                %{
                    "message" => m.message,
                    "user_id" => m.user_id,
                    "current_time" => m.current_time,
                    "id" => m.main_id
                 }
             end)
             json conn, %{success: true, data: messages}
        else
            IO.inspect "Last mesage id không hợp lệ"
            json conn, %{success: false, message: "Last mesage id không hợp lệ"}
        end
    end

    def create_conversation(conn, params) do
        user_id = conn.assigns.current_user.uid
        friend_id = params["friend_id"]
        current_time  = System.os_time(:microsecond)

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
                Repo.transaction(fn ->
                    id = hash_conversation_id([friend_id] ++ [user_id])
                    type = "direct"
                    Conversation.changeset(%Conversation{}, %{type: type, id: id, last_user_send_message: user_id, name: "default", update_by_message: current_time})
                    |> Repo.insert
                    |> case do
                        {:ok, dm} ->
                            data = [%{
                                conversation_id: dm.id,
                                user_id: user_id,
                                seen: true,
                                new_message_count: 0,
                                inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                                updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                                id: hash_conversation_id([dm.id, user_id])
                            }, %{
                                conversation_id: dm.id,
                                user_id: friend_id,
                                seen: false,
                                new_message_count: 1,
                                inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                                updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                                id: hash_conversation_id([dm.id, friend_id])
                            }]
                            Repo.insert_all(ConversationMember, data, returning: true)
                            dm
                        {:error, er} ->
                            IO.inspect er, label: "ERror insert conversation member"
                            {:error}
                    end
                end)
                |>
                case do
                    {:ok, data} ->
                        ([user_id] ++ [friend_id])
                        |> Enum.map(fn u ->
                            Endpoint.broadcast!(
                                "user:#{u}",
                                "create_conversation",
                                %{}
                            )
                        end)
                        json conn, %{success: true, conversation_id: data.id}
                    _ ->
                        IO.inspect "Error transaction"
                        json conn, %{success: false}
                end
            end
        end
        rescue
            err ->
                case err do
                    %Ecto.ConstraintError{} ->
                        user_id = conn.assigns.current_user.uid
                        friend_id = params["friend_id"]
                        id = hash_conversation_id([friend_id] ++ [user_id])
                        json conn, %{success: true, conversation_id: id}
                    _ ->
                        IO.inspect err, label: "ERR"
                        json conn, %{success: false}
                end
    end

    def create_message(conn, params) do
        conversation_id = params["conversation_id"]
        user_id = conn.assigns.current_user.uid
        current_time = System.os_time(:microsecond)
        main_id = Ecto.UUID.generate

        if Repo.get_by(Conversation, %{id: conversation_id}) do
            tran = Repo.transaction(fn ->
                messages = Enum.map(params["messages"], fn m ->
                   %{
                        message: m,
                        conversation_id: conversation_id,
                        current_time: current_time,
                        user_id: user_id,
                        inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                        updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
                        id: main_id
                   }
                end)
                data_insert = Enum.map(messages, fn m ->
                    Map.take(m, [:message, :conversation_id, :current_time, :user_id, :inserted_at, :updated_at])
                    |> Map.put(:main_id, m.id)
                end)
                Repo.insert_all(ConversationMessage, data_insert, returning: true)
                |> case do
                    {0, _} -> {:error}
                    {_, _} ->
                        from(cm in ConversationMember, where: cm.conversation_id == ^conversation_id, select: cm.user_id)
                        |> Repo.all
                        |> Enum.map(fn u ->
                            # IO.inspect "user:#{u}"
                            Endpoint.broadcast!(
                                "user:#{u}",
                                "broadcast_new_message",
                                %{
                                    "data" => messages
                                    |> Enum.map(fn m ->
                                       m |> Map.put("last_user_send_message", user_id)
                                    end)
                                }
                            )
                        end)
                        from(c in Conversation, where: c.id == ^conversation_id)
                        |> Repo.update_all(set: [update_by_message: current_time, last_user_send_message: user_id])
                        from(cm in ConversationMember, where: cm.conversation_id == ^conversation_id and cm.user_id != ^user_id)
                        |> Repo.update_all(set: [seen: false])
                        from(cm in ConversationMember, where: cm.conversation_id == ^conversation_id and cm.user_id == ^user_id)
                        |> Repo.update_all(set: [seen: true])

                end
            end)
            case tran do
                {:ok, _} ->
                    json(conn, %{success: true, data: %{"current_time" => current_time, "id" => main_id}})
                _ ->
                    json(conn, %{success: false})
            end
        else
            IO.inspect "Hội thoại chưa được tạo"
            json(conn, %{success: false, message: "Hội thoại chưa được tạo"})
        end
    end



    def hash_conversation_id(ids) do
        string = ids
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("_")
        :crypto.hash(:sha256, string)
        |> Base.url_encode64()
    end
end
