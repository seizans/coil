defmodule Sand do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Coil.start_http(:sand, coil_conf(), [port: 4000])
    children = [
    ]
    opts = [strategy: :one_for_one, name: Sand.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp coil_conf() do
    [service_name: "Spam",
     middlewares: [Sand.Auth],
     onresponse: [Sand.AddCorsHeader],
     dispatch_config: %{"GetUser" => Sand.User1,
                        "CreateUser" => Sand.User1,
                        "UpdateUser" => Sand.User2,
                        "DeleteUser" => Sand.User2}]
  end
end
