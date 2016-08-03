defmodule Sand.User1 do
  def get_user(_params, _private) do
    {:ok, %{spam: :ham}}
  end

  def create_user(_params, _private) do
    {:error, "FUGAhoge"}
  end

end
