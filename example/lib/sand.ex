defmodule Sand do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Coil.start(:sand, "Spam", "x-spam-target", conf(), 4000)
    children = [
    ]
    opts = [strategy: :one_for_one, name: Sand.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp conf() do
    %{"GetUser" => Sand.User1,
      "CreateUser" => Sand.User1,
      "UpdateUser" => Sand.User2,
      "DeleteUser" => Sand.User2}
  end
end
