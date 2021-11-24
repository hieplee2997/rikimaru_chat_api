defmodule RikimaruChatApiWeb.UserController do
    import Ecto.Query
    use RikimaruChatApiWeb, :controller
    alias RikimaruChatApi.Rikimaru.{User, Tools, UserRelation}
    alias RikimaruChatApi.{Repo}

    plug Rikimaru.API.Plugs.Auth when action in [:fetch_me, :add_friend]

    @field [:id, :full_name, :user_name, :access_token, :avatar_url]
    @secret_key_base "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.VFb0qJ1LRg_4ujbZoRMXnVkUgiuKq5KxWqNdbKq_G9Vvz-S1zZa9LPxtHWKa64zDl2ofkT8F6jBt_K4riU-fPg"

    def password_login(conn, params) do
        user_name = params["userName"]
        password = params["password"]

        user = Repo.get_by(User, %{user_name: user_name |> String.downcase |> String.trim})

        case user do
          nil ->
            json conn, %{success: false, message: "WRONG USERNAME"}
          _ ->
            case Comeonin.Bcrypt.checkpw(password, user.password_hash) do
                true ->
                 iat = Calendar.DateTime.now_utc |> Calendar.DateTime.Format.unix
                 exp = iat + 7760000

                 jwt = JsonWebToken.sign(
                     %{
                         uid: user.id,
                         full_name: user.full_name,
                         iat: iat,
                         exp: exp
                     }, %{key: conn.secret_key_base}
                 )

                 response = %{
                    success: true,
                    access_token: jwt,
                    expire_in: exp,
                    data: Map.take(user, @field),
                    message: "Bạn đã đăng nhập thành công"
                 }

                 json conn, response
                false ->
                 json conn, %{success: false, message: "WRONG PASSWORD"}
             end
        end


    end
    def create_account(conn, params) do
        display_name = params["displayName"]
        user_name = params["userName"]
        password = params["password"]
        # avatar_url = params["avatar_url"]

        cond do
            Tools.is_empty(display_name) or Tools.is_empty(user_name) or Tools.is_empty(password) ->
                json conn, %{success: false, message: "INVALID_FIELD"}
            true ->
                if Repo.get_by(User, %{user_name: user_name}) do
                  json conn, %{success: false, message: "Tài khoản đã tồn tại, vui lòng chọn tên đăng nhập khác"}
                end
                user = %User{
                    user_name: user_name,
                    full_name: display_name,
                    password_hash: Comeonin.Bcrypt.hashpwsalt(password)
                }
                Repo.transaction(fn  ->
                    user = Repo.insert(user)
                    |> case  do
                        {:error, changeset} -> Repo.rollback(changeset)
                        {:ok, create_user} -> create_user
                    end
                    user
                end)
                |> case  do
                {:ok, create_user} ->
                    iat = Calendar.DateTime.now_utc |> Calendar.DateTime.Format.unix
                    exp = iat + 7760000
                    jwt = JsonWebToken.sign(
                        %{
                            uid: create_user.id,
                            iat: iat,
                            exp: exp
                        }, %{key: @secret_key_base}
                    )
                    json conn, %{
                        success: true,
                        access_token: jwt,
                        expire_in: exp,
                        data: Map.take(create_user, @field),
                        message: "Tài khoản đã được tạo thành công"
                    }
                {:error, _} ->
                    json conn, %{success: false, message: "Đã có lỗi xảy ra vui lòng thử lại sau"}
                end
        end
    end
    def fetch_me(conn, _) do
        user_id = conn.assigns.current_user.uid
        case Repo.get_by(User, %{id: user_id}) do
            nil ->
                json conn, %{success: false, message: "User không còn tồn tại trên hệ thống"}
            user ->
                user = Map.take(user, [:full_name, :user_name]) |> Map.put(:user_id, user.id)
                friends = from(
                    u in UserRelation,
                    join: ur in UserRelation,
                    on: u.user_id == ur.friend_id and u.friend_id == ur.user_id,
                    where: u.user_id == ^user_id,
                    select: u.friend_id
                  )
                  |> Repo.all
                  |> Enum.map(fn id ->
                        Repo.get_by(User, %{id: id}) |> Map.take([:full_name, :user_name]) |> Map.put(:user_id, id)
                    end)
                json conn, %{success: true, user: user, friends: friends}
        end
    end
    def add_friend(conn, params) do
        user_id = conn.assigns.current_user.uid
        user_name_add = if params["user_name"] != nil, do: params["user_name"], else: ""

        if user_name_add != "" do
            user = Repo.get_by(User, %{user_name: user_name_add})
            if user do
              is_not_friend = from(
                u in UserRelation,
                join: ur in UserRelation,
                on: ur.user_id == u.friend_id and ur.friend_id == u.user_id,
                where: u.user_id == ^user_id and u.friend_id == ^user.id,
                limit: 1,
                offset: 0,
                select: u.friend_id
              ) |> Repo.all |> Enum.empty?()
              if is_not_friend == false do
                json conn, %{success: false, message: "Người này đã là bạn bè của bạn"}
              else
                %UserRelation{
                    user_id: user_id,
                    friend_id: user.id
                  }
                  |> Repo.insert
                  %UserRelation{
                    user_id: user.id,
                    friend_id: user_id
                  }
                  |> Repo.insert
                  user = user |> Map.take([:full_name, :user_name]) |> Map.put(:user_id, user.id)
                  json conn, %{success: true, friend: user}
              end
            else
                json conn, %{success: false, message: "Tài khoản không tồn tại"}
            end
        else
            json conn, %{success: false, message: "Tên người dùng không được rỗng"}
        end
    end
end
