defmodule Coil.Handler do
  import Plug.Conn

  def dispatch(conn, params) do
    IO.inspect params
    header_name = "x-coil"
    case get_req_header(conn, header_name) do
      [header_value] ->
        case Regex.run(~r/^([a-zA-Z]+)_(\d{8}).([a-zA-Z]+)$/, header_value, [capture: :all_but_first]) do
          [service, version, operation] ->
            IO.inspect service
            IO.inspect version
            IO.inspect operation
            conn
            |> send_resp(200, "dispatch")
          _ ->
            conn
            |> send_resp(400, "Invalid header value")
        end
      [] ->
        conn
        |> send_resp(400, "No header")
    end
  end
end
