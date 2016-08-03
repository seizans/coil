defmodule Sand.Auth do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      [value] ->
        conn
        |> put_private(:user, value)
      [] ->
        conn
        |> resp(401, "No authorization header")
        |> halt()
    end
  end
end
