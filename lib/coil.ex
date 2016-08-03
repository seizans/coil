defmodule Coil do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Coil.JsonSchema.start()
    Coil.Dispatch.start()
    children = [
    ]
    opts = [strategy: :one_for_one, name: Coil.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec start_http(atom, keyword, keyword) :: {:ok, pid}
  def start_http(app_name, coil_config, cowboy_opts \\ []) do
    # TODO(seizans): opts は ets に格納した方がいいのかどうか
    # TODO(seizans): dispatch_conf 内の operation に対応する mod:fun が存在するか起動時にチェックする
    service_name = Keyword.fetch!(coil_config, :service_name)
    dispatch_config = Keyword.fetch!(coil_config, :dispatch_config)
    Coil.JsonSchema.load_schemas(app_name, service_name, dispatch_config)
    Coil.Dispatch.load_dispatch(service_name, dispatch_config)
    Plug.Adapters.Cowboy.http(Coil.Handler, coil_config, cowboy_opts)
  end
end
