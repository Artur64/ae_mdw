defmodule AeMdw.Db.Sync.Transaction do
  @moduledoc "assumes block index is in place, syncs whole history"

  alias AeMdw.Node, as: AE
  alias AeMdw.Db.Model
  alias AeMdw.Db.Sync
  alias AeMdw.Db.Stream, as: DBS

  require Model

  import AeMdw.{Sigil, Util, Db.Util}

  @log_freq 1000

  ################################################################################

  def sync(max_height \\ :safe) do
    max_height = Sync.height((is_integer(max_height) && max_height + 1) || max_height)
    bi_max_kbi = Sync.BlockIndex.sync(max_height) - 1

    case max_txi() do
      nil ->
        sync(0, bi_max_kbi, 0)

      max_txi when is_integer(max_txi) ->
        {tx_kbi, _} = Model.tx(read_tx!(max_txi), :block_index)
        next_txi = max_txi + 1
        from_height = tx_kbi + 1
        sync(from_height, bi_max_kbi, next_txi)
    end
  end

  def sync(from_height, to_height, txi) when from_height <= to_height do
    tracker = Sync.progress_logger(&sync_generation/2, @log_freq, &log_msg/2)
    next_txi = from_height..to_height |> Enum.reduce(txi, tracker)

    :mnesia.transaction(fn ->
      [succ_kb] = :mnesia.read(Model.Block, {to_height + 1, -1})
      :mnesia.write(Model.Block, Model.block(succ_kb, tx_index: next_txi), :write)
    end)

    next_txi
  end

  def sync(from_height, to_height, txi) when from_height > to_height,
    do: txi

  def clear() do
    for tab <- [~t[tx], ~t[type], ~t[time], ~t[field], ~t[id_count], ~t[origin], ~t[rev_origin]],
        do: :mnesia.clear_table(tab)
  end

  def min_txi(), do: txi(&first/1)
  def max_txi(), do: txi(&last/1)

  def min_kbi(), do: kbi(&first/1)
  def max_kbi(), do: kbi(&last/1)

  ################################################################################

  defp sync_generation(height, txi) do
    {key_block, micro_blocks} = AE.Db.get_blocks(height)

    {:atomic, {next_txi, _mb_index}} =
      :mnesia.transaction(fn ->
        kb_txi = (txi == 0 && -1) || txi
        kb_hash = :aec_headers.hash_header(:aec_blocks.to_key_header(key_block)) |> ok!
        kb_model = Model.block(index: {height, -1}, tx_index: kb_txi, hash: kb_hash)
        :mnesia.write(Model.Block, kb_model, :write)
        micro_blocks |> Enum.reduce({txi, 0}, &sync_micro_block/2)
      end)

    next_txi
  end

  defp sync_micro_block(mblock, {txi, mbi}) do
    height = :aec_blocks.height(mblock)
    mb_time = :aec_blocks.time_in_msecs(mblock)
    mb_hash = :aec_headers.hash_header(:aec_blocks.to_micro_header(mblock)) |> ok!
    syncer = &sync_transaction(&1, &2, {{height, mbi}, mb_time})
    mb_txi = (txi == 0 && -1) || txi
    mb_model = Model.block(index: {height, mbi}, tx_index: mb_txi, hash: mb_hash)
    :mnesia.write(Model.Block, mb_model, :write)
    next_txi = :aec_blocks.txs(mblock) |> Enum.reduce(txi, syncer)
    {next_txi, mbi + 1}
  end

  defp sync_transaction(signed_tx, txi, {block_index, mb_time}) do
    {mod, tx} = :aetx.specialize_callback(:aetx_sign.tx(signed_tx))
    hash = :aetx_sign.hash(signed_tx)
    type = mod.type()
    model_tx = Model.tx(index: txi, id: hash, block_index: block_index, time: mb_time)
    :mnesia.write(Model.Tx, model_tx, :write)
    :mnesia.write(Model.Type, Model.type(index: {type, txi}), :write)
    :mnesia.write(Model.Time, Model.time(index: {mb_time, txi}), :write)
    write_links(type, tx, signed_tx, txi, hash, block_index)

    for {_field, pos} <- AE.tx_ids(type) do
      {_tag, pk} = :aeser_id.specialize(elem(tx, pos))
      write_field(type, pos, pk, txi)
    end

    txi + 1
  end

  def write_field(type, pos, pk, txi) do
    model_fld = Model.field(index: {type, pos, pk, txi})
    :mnesia.write(Model.Field, model_fld, :write)
    Model.incr_count({type, pos, pk})
  end

  def write_links(:contract_create_tx, tx, _signed_tx, txi, tx_hash, _bi) do
    pk = :aect_contracts.pubkey(:aect_contracts.new(tx))
    write_field(:contract_create_tx, nil, pk, txi)
    write_origin({:contract_create_tx, pk, txi}, tx_hash)
  end

  def write_links(:channel_create_tx, _tx, signed_tx, txi, tx_hash, _bi) do
    {:ok, pk} = :aesc_utils.channel_pubkey(signed_tx)
    write_field(:channel_create_tx, nil, pk, txi)
    write_origin({:channel_create_tx, pk, txi}, tx_hash)
  end

  def write_links(:oracle_register_tx, tx, _signed_tx, txi, tx_hash, _bi) do
    pk = :aeo_register_tx.account_pubkey(tx)
    write_field(:oracle_register_tx, nil, pk, txi)
    write_origin({:oracle_register_tx, pk, txi}, tx_hash)
  end

  def write_links(:name_claim_tx, tx, signed_tx, txi, tx_hash, bi) do
    name = :aens_claim_tx.name(tx)
    {:ok, name_hash} = :aens.get_name_hash(name)
    write_field(:name_claim_tx, nil, name_hash, txi)
    write_origin({:name_claim_tx, name_hash, txi}, tx_hash)
    :mnesia.write(Model.Name, Model.name(id: name_hash, name: name), :write)
    #Sync.Name.claim(name, name_hash, tx, txi, tx_hash, bi)
  end

  ## TODO: pointers !!
  # def write_links(:name_update_tx, tx, signed_tx, txi, tx_hash, bi),
  #   do: Sync.Name.update(:aens_update_tx.name_hash(tx), tx, txi, tx_hash, bi)

  def write_links(_, _, _, _, _, _),
    do: :ok

  defp write_origin({tx_type, pubkey, txi}, tx_hash) do
    origin = Model.origin(index: {tx_type, pubkey, txi}, tx_id: tx_hash)
    rev_origin = Model.rev_origin(index: {txi, tx_type, pubkey})
    :mnesia.write(Model.Origin, origin, :write)
    :mnesia.write(Model.RevOrigin, rev_origin, :write)
  end

  ##########

  defp txi(f) do
    case f.(Model.Tx) do
      :"$end_of_table" -> nil
      txi -> txi
    end
  end

  defp kbi(f) do
    case f.(Model.Tx) do
      :"$end_of_table" -> nil
      txi -> Model.tx(read_tx!(txi), :block_index) |> elem(0)
    end
  end

  defp log_msg(height, _),
    do: "syncing transactions at generation #{height}"

end
