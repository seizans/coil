defmodule Coil.JsonSchema do
  @moduledoc """
  start_link 時に priv/json_schema/ 以下の .json ファイルからスキーマを ets に読み込む。
  """

  # TODO(seizans): service 複数にした場合の名前をどうするか考える
  @table_name :coil_json_schema_ets

  def start(app_name, service_name, dispatch_conf) do
    :ets.new(@table_name, [:set, :public, :named_table])
    service_name_underscore = Macro.underscore(service_name)
    dir = Application.app_dir(app_name, Path.join("priv/json_schema", service_name_underscore))
    for {operation, _module} <- dispatch_conf do
      schema = Path.join(dir, "#{Macro.underscore(operation)}.json")
               |> File.read!()
               |> Poison.decode!()
               |> ExJsonSchema.Schema.resolve()
      key = {service_name, operation}
      :ets.insert(@table_name, {key, schema})
    end
  end

  def validate(service_name, operation, params) do
    key = {service_name, operation}
    case :ets.lookup(@table_name, key) do
      [{^key, schema}] ->
        ExJsonSchema.Validator.validate(schema, params)
      [] ->
        {:error, :not_found}
    end
  end
end
