defmodule AeMdw.Extract do

  @moduledoc "currently we require that AE node is compiled with debug_info"

  import AeMdw.Util


  defmodule AbsCode do

    def module(module) do
      with [_|_] = path <- :code.which(module),
           {:ok, chunk} = :beam_lib.chunks(path, [:abstract_code]),
           {_, [abstract_code: {_, code}]} <- chunk,
        do: {:ok, code}
    end

    def function(mod_code, name, arity) do
      finder = fn {:function, _, ^name, ^arity, code} -> code; _ -> nil end
      with [_|_] = fn_code <- Enum.find_value(mod_code, finder),
        do: {:ok, fn_code}
    end

    def record_fields(mod_code, name) do
      finder = fn {:attribute, _, :record, {^name, fields}} -> fields; _ -> nil end
      with [_|_] = rec_fields <- Enum.find_value(mod_code, finder),
        do: {:ok, rec_fields}
    end

  end


  def tx_types() do
    {:ok,
     Code.Typespec.fetch_types(:aetx)
     |> ok!
     |> Enum.find_value(nil, &tx_type_variants/1)}
  end

  defp tx_type_variants({:type, {:tx_type, {:type, _, :union, variants}, []}}),
    do: for {:atom, _, v} <- variants, do: v
  defp tx_type_variants(_), do: nil


  def tx_map() do
    with {:ok, mod_code} <- AbsCode.module(:aetx),
         {:ok, fn_code}  <- AbsCode.function(mod_code, :type_to_cb, 1) do
      type_mod = fn {:clause, _, [{:atom, _, t}], [], [{:atom, _, m}]} -> {t, m} end
      {:ok,
       fn_code
       |> Enum.map(type_mod)
       |> Enum.into(%{})}
    end
  end


  defp tx_record(:name_preclaim_tx), do: :ns_preclaim_tx
  defp tx_record(:name_claim_tx),    do: :ns_claim_tx
  defp tx_record(:name_transfer_tx), do: :ns_transfer_tx
  defp tx_record(:name_update_tx),   do: :ns_update_tx
  defp tx_record(:name_revoke_tx),   do: :ns_revoke_tx
  defp tx_record(tx_type),           do: tx_type


  def tx_getters(:channel_client_reconnect_tx), do: {:ok, %{}}
  def tx_getters(tx_type) do
    with {:ok, mod_name} <- AeMdw.Db.Model.get_meta({:tx_mod, tx_type}),
         {:ok, mod_code} <- AbsCode.module(mod_name),
         {:ok, rec_code} <- AbsCode.record_fields(mod_code, tx_record(tx_type)),
      do: {:ok,
           rec_code
           |> Stream.with_index(1)
           |> Stream.map(fn {ast, i} -> {tx_id_field(ast), i} end)
           |> Stream.reject(fn {field, _} -> is_nil(field) end)
           |> Enum.into(%{})}
  end

  defp tx_id_field({:typed_record_field, {:record_field, _, {:atom, _, field}},
                     {:remote_type, _, [{:atom, _, :aeser_id}, {:atom, _, :id}, []]}}),
    do: field
  defp tx_id_field({:typed_record_field, {:record_field, _, {:atom, _, field}},
                     {:type, _, :list,
                      [{:remote_type, _, [{:atom, _, :aeser_id}, {:atom, _, :id}, []]}]}}),
    do: field
  defp tx_id_field(_), do: nil

end