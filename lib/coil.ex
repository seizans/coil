defmodule Coil do
  def child_spec(port, coil_header_name) do
    # TODO(seizans): plug_opts と cowboy_opts を渡せる必要があれば渡せるようにする
    Plug.Adapters.Cowboy.child_spec(:http, Coil.Handler, %{coil_header_name: coil_header_name}, [port: port])
  end
end
