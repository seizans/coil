defmodule Sand.AddCorsHeader do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("Access-Control-Allow-Origin", "*")
  end
end
