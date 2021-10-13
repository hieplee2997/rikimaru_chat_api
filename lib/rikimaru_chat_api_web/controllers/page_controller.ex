defmodule RikimaruChatApiWeb.PageController do
  use RikimaruChatApiWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
