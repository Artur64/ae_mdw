defmodule AeMdw.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    init(:meta)

    children = [
      AeMdw.Db.Sync.Supervisor,
      AeMdwWeb.Supervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  def init(:meta) do
    alias AeMdw.Extract

    {:ok, aetx_code} = Extract.AbsCode.module(:aetx)

    type_mod_map = Extract.tx_mod_map(aetx_code)
    type_name_map = Extract.tx_name_map(aetx_code)
    id_prefix_type_map = Extract.id_prefix_type_map()
    type_mod_mapper = &Map.fetch!(type_mod_map, &1)

    {tx_fields, tx_ids} =
      Enum.reduce(type_mod_map, {%{}, %{}}, fn {type, _}, {tx_fields, tx_ids} ->
        {fields, ids} = Extract.tx_record_info(type, type_mod_mapper)
        {put_in(tx_fields[type], fields), put_in(tx_ids[type], ids)}
      end)

    SmartGlobal.new(
      AeMdw.Node,
      %{
        tx_mod: type_mod_map,
        tx_name: type_name_map,
        tx_type: AeMdw.Util.inverse(type_name_map),
        tx_fields: tx_fields,
        tx_ids: tx_ids,
        id_prefix: id_prefix_type_map,
        # for quicker testing without try/rescue
        tx_types: [{[], MapSet.new(Map.keys(type_mod_map))}],
        tx_names: [{[], MapSet.new(Map.values(type_name_map))}],
        id_prefixes: [{[], MapSet.new(Map.keys(id_prefix_type_map))}]
      }
    )
  end

  # Tell Phoenix to update the endpoint configuration whenever the application is updated.
  def config_change(changed, _new, removed) do
    AeMdwWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
