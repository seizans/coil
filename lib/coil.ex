defmodule Coil do
  @spec start(atom, binary, binary, map, keyword) :: {:ok, pid}
  def start(app_name, service_name, coil_header_name, dispatch_conf, cowboy_opts \\ []) do
    # TODO(seizans): opts は ets に格納した方がいいのかどうか
    # TODO(seizans): dispatch_conf 内の operation に対応する mod:fun が存在するか起動時にチェックする
    opts = %{service_name: service_name,
             coil_header_name: coil_header_name,
             dispatch_conf: dispatch_conf}
    Coil.JsonSchema.start(app_name, service_name, dispatch_conf)
    Plug.Adapters.Cowboy.http(Coil.Handler, opts, cowboy_opts)
  end
end
