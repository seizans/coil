defmodule Coil do
  def child_spec(port) do
    # TODO(seizans): plug_opts と cowboy_opts を渡せる必要があれば渡せるようにする
    Plug.Adapters.Cowboy.child_spec(:http, Coil.Router, [], port: port)
  end
end
