defmodule Rikimaru.API.Plugs.Auth do
  import Plug.Conn
  alias RikimaruChatApi.Rikimaru.{Tools}

  @secret_key_base "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.VFb0qJ1LRg_4ujbZoRMXnVkUgiuKq5KxWqNdbKq_G9Vvz-S1zZa9LPxtHWKa64zDl2ofkT8F6jBt_K4riU-fPg"

  def init(opts) do
    opts
  end
  def call(conn, _) do
    case conn.query_params["token"] do
      nil -> Tools.json_error(conn, "Thiếu token", 200, 101)
      "null" -> Tools.json_error(conn, "Token null", 200, 102)
      "undefined" -> Tools.json_error(conn, "Token undefined", 200, 102)
      token ->
        case validate_token(conn, token) do
          :invalid_token -> Tools.json_error(conn, "Sai token", 200, 102)
          :expired_token -> Tools.json_error(conn, "token đã hết hạn", 200, 103)
          :invalid_user -> Tools.json_error(conn, "Sai user_id", 200, 104)
          :no_user_permission -> Tools.json_error(conn, "Không có quyền hạn trên trang này. Nếu trang vừa được cập nhập gần đây, vui lòng đăng nhập lại", 200, 105)
          assigned_conn -> assigned_conn
        end
    end
  end

  def validate_token(conn, token) do
    try do
      case JsonWebToken.verify(token, %{key: @secret_key_base}) do
        {:ok, claims} ->
          user = Map.take(claims, [:uid, :full_name])
          if user do
            assign(conn, :current_user, user)
          else
            :invalid_user
          end
          # cond do
          #   claims.exp > current_timestamp ->
          #     user = Map.take(claims, [:uid, :full_name])
          #     if user do
          #       assign(conn, :current_user, user)
          #     else
          #       :invalid_user
          #     end
          #   true -> :expired_token
          # end
        {:error, _} -> :invalid_token
      end
    rescue
      RuntimeError -> :invalid_token
    end
  end


end
