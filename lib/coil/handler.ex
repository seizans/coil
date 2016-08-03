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
    middlewares = Keyword.get(opts, :middlewares, [])
    onresponse = Keyword.get(opts, :onresponse, [])

    conn
    |> call_plug(Plug.Logger)
    |> call_plug(Plug.Parsers, parsers: [:json],
                               pass: ["application/json"],
                               json_decoder: Poison)
    |> call_plugs(middlewares)
    |> handle(service_name, coil_header_name, dispatch_conf)
    |> call_plugs(onresponse)
    |> send_resp()
  end
  def call(conn, _opts) do
    conn
    |> put_status(400)
    |> json(%{error: "Request path must be '/'"})
  end

  defp call_plug(conn, plug, opts \\ []) do
    if conn.halted do
      conn
    else
      plug.call(conn, plug.init(opts))
    end
  end

  def call_plugs(conn, plugs) do
    Enum.reduce(plugs, conn, fn(plug, conn) -> call_plug(conn, plug) end)
  end

  defp handle(%Plug.Conn{halted: true} = conn, _service_name, _coil_header_name, _dispatch_conf) do
    conn
  end
  defp handle(conn, service_name, coil_header_name, dispatch_conf) do
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
                        |> resp(200, "")
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
                    |> resp(400, message)
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
    |> resp(conn.status || 200, Poison.encode_to_iodata!(data))
  end
end
