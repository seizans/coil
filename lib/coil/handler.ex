defmodule Coil.Handler do
  @behaviour Plug
  use Plug.ErrorHandler
  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/"} = conn, opts) do
    service_name = Keyword.fetch!(opts, :service_name)
    coil_header_name = Keyword.fetch!(opts, :coil_header_name)
    dispatch_conf = Keyword.fetch!(opts, :dispatch_conf)
    # TODO(seizans): メイン処理の前と後に plug を追加できるようにする
    conn
    |> call_plug(Plug.Logger)
    |> call_plug(Plug.Parsers, parsers: [:json],
                               pass: ["application/json"],
                               json_decoder: Poison)
    |> handle(service_name, coil_header_name, dispatch_conf)
  end
  def call(conn, _opts) do
    conn
    |> send_resp(400, "Request path must be '/'")
  end

  defp call_plug(conn, plug, opts \\ []) do
    plug.call(conn, plug.init(opts))
  end

  def call_plugs(conn, plugs, opts \\ []) do
    Enum.reduce(plugs, conn, fn(plug, conn) -> call_plug(conn, plug, opts) end)
  end

  def handle(conn, service_name, coil_header_name, dispatch_conf) do
    case get_req_header(conn, coil_header_name) do
      [header_value] ->
        case Regex.run(~r/^([a-zA-Z]+).([a-zA-Z]+)$/, header_value, [capture: :all_but_first]) do
          [^service_name, operation] ->
            case Map.get(dispatch_conf, operation) do
              nil ->
                conn
                |> put_status(400)
                |> json(%{error: "Invalid operation name"})
              module ->
                case Coil.JsonSchema.validate(service_name, operation, conn.params) do
                  :ok ->
                    fun = operation
                          |> Macro.underscore()
                          |> String.to_atom()
                    case apply(module, fun, [conn.params, conn.private]) do
                      :ok ->
                        conn
                        |> send_resp(200, "")
                      {:ok, data} ->
                        conn
                        |> json(data)
                      {:error, reason} ->
                        conn
                        |> put_status(400)
                        |> json(%{error: reason})
                    end
                  {:error, reasons} when is_list(reasons) ->
                    # TODO(seizans): なんとかする
                    message = %{reason: to_string(Enum.map(reasons, &Tuple.to_list(&1)))}
                              |> Poison.encode!()
                    conn
                    |> send_resp(400, message)
                end
            end
          _ ->
            conn
            |> put_status(400)
            |> json(%{error: "Invalid header value"})
        end
      [] ->
        conn
        |> put_status(400)
        |> json(%{error: "No header"})
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
  defp json(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(conn.status || 200, Poison.encode_to_iodata!(data))
  end
end
