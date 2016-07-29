defmodule Coil do
  # TODO(seizans): service 複数に対応できるようにするか
  @spec start(atom(), binary(), binary(), map(), non_neg_integer()) :: {:ok, pid()}
  def start(app_name, service_name, coil_header_name, dispatch_conf, port) do
    # TODO(seizans): ets に格納した方がいいかどうか
    # TODO(seizans): dispatch_conf 内の operation に対応する mod:fun が存在するか起動時にチェックする
    opts = %{service_name: service_name,
             coil_header_name: coil_header_name,
             dispatch_conf: dispatch_conf}
    Coil.JsonSchema.start(app_name, service_name, dispatch_conf)
    # TODO(seizans): cowboy_opts を渡せる必要があるか検討する
    Plug.Adapters.Cowboy.http(Coil.Handler, opts, [port: port])
  end
end
