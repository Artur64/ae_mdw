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

    def field_name_type({:typed_record_field, {:record_field, _, {:atom, _, name}}, type}),
      do: {name, type}
    def field_name_type({:typed_record_field, {:record_field, _, {:atom, _, name}, _}, type}),
      do: {name, type}

    def aeser_id_type?(abs_code) do
      case abs_code do
        {:remote_type, _, [{:atom, _, :aeser_id}, {:atom, _, :id}, []]} -> true
        _ -> false
      end
    end

    def list_of_aeser_id_type?(abs_code) do
      case abs_code do
        {:type, _, :list,
          [{:remote_type, _, [{:atom, _, :aeser_id}, {:atom, _, :id}, []]}]} -> true
        _ ->
          false
      end
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


  def tx_record_info(:channel_client_reconnect_tx),
    do: {:ok, [], %{}}
  def tx_record_info(tx_type) do
    mod_name = AeMdw.Node.tx_mod(tx_type)
    mod_code = AbsCode.module(mod_name) |> ok!
    rec_code = AbsCode.record_fields(mod_code, tx_record(tx_type)) |> ok!
    {rev_names, ids} =
      rec_code
      |> Stream.with_index(1)
      |> Enum.reduce({[], %{}},
           fn {ast, i}, {names, ids} ->
             {name, type} = AbsCode.field_name_type(ast)
             id? = AbsCode.aeser_id_type?(type) || AbsCode.list_of_aeser_id_type?(type)
             {[name | names], id? && put_in(ids[name], i) || ids}
           end)
    {:ok, Enum.reverse(rev_names), ids}
  end

end
