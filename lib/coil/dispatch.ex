defmodule Coil.Dispatch do
  @table_name :coil_dispatch_ets

  def start() do
    :ets.new(@table_name, [:set, :public, :named_table])
  end

  def load_dispatch(service_name, dispatch_config) do
    for {operation, module} <- dispatch_config do
      key = {service_name, operation}
      :ets.insert(@table_name, {key, module})
    end
  end

  def get(service_name, operation) do
    key = {service_name, operation}
    case :ets.lookup(@table_name, key) do
      [{^key, module}] ->
        module
      [] ->
        nil
    end
  end
end
