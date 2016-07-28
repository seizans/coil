defmodule Coil.Handler do
  use Plug.ErrorHandler
  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(conn, %{coil_header_name: coil_header_name} = _opts) do
    conn
    |> call_plug(Plug.Logger, [])
    |> call_plug(Plug.Parsers, parsers: [:json],
                               pass: ["application/json"],
                               json_decoder: Poison)
    |> handle(coil_header_name)
  end

  defp call_plug(conn, plug, opts) do
    plug.call(conn, plug.init(opts))
  end

  def handle(%Plug.Conn{request_path: "/"} = conn, coil_header_name) do
    IO.inspect coil_header_name
    IO.inspect conn
    IO.inspect conn.private
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
  def dispatch(conn, _coil_header_name) do
    IO.inspect conn
    conn
    |> send_resp(400, "Request path must be '/'")
  end

  defp handle_errors(conn, %{kind: :error, reason: %Plug.Parsers.UnsupportedMediaTypeError{media_type: media_type}}) do
    Logger.info("#{media_type} is unsupported media type")
    conn
    |> json(%{error: "#{media_type} is unsupported media type"})
  end
  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack} = params) do
    Logger.info(params)
    conn
    |> json(%{error: "Something went wrong"})
  end

  @spec json(Plug.Conn.t, map) :: Plug.Conn.t
  def json(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(conn.status || 200, Poison.encode_to_iodata!(data))
  end
end
