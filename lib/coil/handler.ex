defmodule Coil.Handler do
  use Plug.ErrorHandler
  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/"} = conn, %{service_name: service_name,
                                                   coil_header_name: coil_header_name,
                                                   dispatch_conf: dispatch_conf} = _opts) do
    conn
    |> call_plug(Plug.Logger, [])
    |> call_plug(Plug.Parsers, parsers: [:json],
                               pass: ["application/json"],
                               json_decoder: Poison)
    |> handle(service_name, coil_header_name, dispatch_conf)
  end
  def call(conn, _opts) do
    conn
    |> send_resp(400, "Request path must be '/'")
  end

  defp call_plug(conn, plug, opts) do
    plug.call(conn, plug.init(opts))
  end

  def handle(conn, service_name, coil_header_name, dispatch_conf) do
    case get_req_header(conn, coil_header_name) do
      [header_value] ->
        case Regex.run(~r/^([a-zA-Z]+).([a-zA-Z]+)$/, header_value, [capture: :all_but_first]) do
          [^service_name, operation] ->
            case Map.get(dispatch_conf, operation) do
              nil ->
                conn
                |> send_resp(400, "Invalid operation name")
              module ->
                # TODO(seizans): conn.params を json_schema で validate する
                fun = operation
                      |> Macro.underscore()
                      |> String.to_atom()
                IO.inspect conn
                IO.inspect conn.params
                # TODO(seizans): 引数を必要なものに限定し、返り値も限定して、conn はこちらのみで使う
                apply(module, fun, [conn])
                |> send_resp(200, "dispatched")
            end
          _ ->
            conn
            |> send_resp(400, "Invalid header value")
        end
      [] ->
        conn
        |> send_resp(400, "No header")
    end
  end

  defp handle_errors(conn, %{kind: :error, reason: %Plug.Parsers.UnsupportedMediaTypeError{media_type: media_type}}) do
    conn
    |> json(%{error: "#{media_type} is unsupported media type"})
  end
  defp handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack} = _params) do
    Exception.message(reason)
    |> Logger.error()
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
