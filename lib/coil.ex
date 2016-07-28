defmodule Coil do
  def child_spec(port, service_name, coil_header_name, dispatch_conf) do
    # TODO(seizans): dispatch_conf 内の operation に対応する mod:fun が存在するか起動時にチェックする
    # TODO(seizans): cowboy_opts を渡せる必要があれば渡せるようにする
    Plug.Adapters.Cowboy.child_spec(:http,
                                    Coil.Handler,
                                    %{coil_header_name: coil_header_name,
                                      service_name: service_name,
                                      dispatch_conf: dispatch_conf},
                                    [port: port])
  end
end
