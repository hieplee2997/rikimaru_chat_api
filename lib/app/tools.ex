defmodule Rikimaru.Tools do
  import Plug.Conn
  def json_error(conn, message, code \\ 400, error_code \\ nil) do
    response = %{success: false}
    |> append_map_key(:message, message)
    |> append_map_key(:error_code, error_code)

    conn
    |> put_resp_header("content-type", "application/json; charset=UTF-8")
    |> send_resp(code, Jason.encode!(response))
    |> halt
  end

  def append_map_key(map, key, value) do
    if key && value do
      Map.put(map, key, value)
    else
      map
    end
  end
end
