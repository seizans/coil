defmodule Coil do
  @spec start(atom, keyword, keyword) :: {:ok, pid}
  def start(app_name, coil_conf, cowboy_opts \\ []) do
    # TODO(seizans): opts は ets に格納した方がいいのかどうか
    # TODO(seizans): dispatch_conf 内の operation に対応する mod:fun が存在するか起動時にチェックする
    service_name = Keyword.fetch!(coil_conf, :service_name)
    dispatch_conf = Keyword.fetch!(coil_conf, :dispatch_conf)
    Coil.JsonSchema.start(app_name, service_name, dispatch_conf)
    Plug.Adapters.Cowboy.http(Coil.Handler, coil_conf, cowboy_opts)
  end
end
