defmodule AeMdwWeb.NameController do
  use AeMdwWeb, :controller

  alias AeMdw.Validate
  alias AeMdw.Db.Name
  alias AeMdw.Db.Model
  alias AeMdw.Db.Format
  alias AeMdw.Db.Stream, as: DBS
  alias AeMdw.Error.Input, as: ErrInput
  alias AeMdwWeb.Continuation, as: Cont
  require Model

  import AeMdwWeb.Util
  import AeMdw.{Util, Db.Util}

  ##########

  def stream_plug_hook(%Plug.Conn{params: params} = conn) do
    alias AeMdwWeb.DataStreamPlug, as: P

    rem = rem_path(conn.path_info)

    P.handle_assign(
      conn,
      (rem == [] && {:ok, {:gen, last_gen()..0}}) || P.parse_scope(rem, ["gen"]),
      P.parse_offset(params),
      {:ok, %{}}
    )
  end

  defp rem_path(["names", x | rem]) when x in ["auctions", "inactive", "active"], do: rem
  defp rem_path(["names" | rem]), do: rem

  ##########

  def name(conn, %{"id" => ident}),
    do: handle_input(conn, fn -> name_reply(conn, Validate.plain_name!(ident)) end)

  def pointers(conn, %{"id" => ident}),
    do: handle_input(conn, fn -> pointers_reply(conn, Validate.plain_name!(ident)) end)

  def pointees(conn, %{"id" => ident}),
    do:
      handle_input(conn, fn ->
        pk =
          map_ok_nil(Validate.plain_name(ident), &ok!(:aens.get_name_hash(&1))) ||
            Validate.id!(ident)

        pointees_reply(conn, pk)
      end)

  def auctions(conn, _req),
    do: handle_input(conn, fn -> Cont.response(conn, &json/2) end)

  def inactive_names(conn, _req),
    do: handle_input(conn, fn -> Cont.response(conn, &json/2) end)

  def active_names(conn, _req),
    do: handle_input(conn, fn -> Cont.response(conn, &json/2) end)

  def names(conn, _req),
    do: handle_input(conn, fn -> Cont.response(conn, &json/2) end)

  ##########

  # scope is used here only for identification of the continuation
  def db_stream(:auctions, params, _scope),
    do: do_auctions_stream(validate_params!(params))

  def db_stream(:inactive_names, params, _scope),
    do: do_inactive_names_stream(validate_params!(params))

  def db_stream(:active_names, params, _scope),
    do: do_active_names_stream(validate_params!(params))

  def db_stream(:names, params, _scope),
    do: do_names_stream(validate_params!(params))

  ##########

  def name_reply(conn, plain_name) do
    with {info, source} <- Name.locate(plain_name) do
      json(conn, Format.to_map(info, source))
    else
      nil ->
        raise ErrInput.NotFound, value: plain_name
    end
  end

  def pointers_reply(conn, plain_name) do
    with {m_name, Model.ActiveName} <- Name.locate(plain_name) do
      json(conn, Format.map_raw_values(Name.pointers(m_name), &Format.to_json/1))
    else
      {_, Model.InactiveName} ->
        raise ErrInput.Expired, value: plain_name

      _ ->
        raise ErrInput.NotFound, value: plain_name
    end
  end

  def pointees_reply(conn, pubkey) do
    {active, inactive} = Name.pointees(pubkey)

    json(conn, %{
      "active" => Format.map_raw_values(active, &Format.to_json/1),
      "inactive" => Format.map_raw_values(inactive, &Format.to_json/1)
    })
  end

  def do_auctions_stream({:name, _} = params),
    do: DBS.Name.auctions(params, &Format.to_map(&1, Model.AuctionBid))

  def do_auctions_stream({:expiration, _} = params) do
    mapper =
      &:mnesia.async_dirty(fn ->
        k = Name.auction_bid_key(&1)
        k && Format.to_map(k, Model.AuctionBid)
      end)

    DBS.Name.auctions(params, mapper)
  end

  def do_inactive_names_stream({:name, _} = params),
    do: DBS.Name.inactive_names(params, &Format.to_map(&1, Model.InactiveName))

  def do_inactive_names_stream({:expiration, _} = params),
    do: DBS.Name.inactive_names(params, exp_to_formatted_name(Model.InactiveName))

  def do_active_names_stream({:name, _} = params),
    do: DBS.Name.active_names(params, &Format.to_map(&1, Model.ActiveName))

  def do_active_names_stream({:expiration, _} = params),
    do: DBS.Name.active_names(params, exp_to_formatted_name(Model.ActiveName))

  def do_names_stream({:name, dir}) do
    streams = [do_inactive_names_stream({:name, dir}), do_active_names_stream({:name, dir})]
    merged_stream(streams, & &1["name"], dir)
  end

  def do_names_stream({:expiration, :forward} = params),
    do: Stream.concat(do_inactive_names_stream(params), do_active_names_stream(params))

  def do_names_stream({:expiration, :backward} = params),
    do: Stream.concat(do_active_names_stream(params), do_inactive_names_stream(params))

  ##########

  def validate_params!(%{"by" => [what], "direction" => [dir]}) do
    what in ["name", "expiration"] || raise ErrInput.Query, value: "by=#{what}"
    dir in ["forward", "backward"] || raise ErrInput.Query, value: "direction=#{dir}"
    {String.to_atom(what), String.to_atom(dir)}
  end

  def validate_params!(%{"by" => [what]}) do
    what in ["name", "expiration"] || raise ErrInput.Query, value: "by=#{what}"
    {String.to_atom(what), :forward}
  end

  def validate_params!(params) when map_size(params) > 0 do
    badkey = hd(Map.keys(params))
    raise ErrInput.Query, value: "#{badkey}=#{Map.get(params, badkey)}"
  end

  def validate_params!(_params), do: {:expiration, :backward}

  def exp_to_formatted_name(table) do
    fn {:expiration, {_, plain_name}, _} ->
      case Name.locate(plain_name) do
        {m_name, ^table} -> Format.to_map(m_name, table)
        _ -> nil
      end
    end
  end

  ##########

  def t() do
    pk =
      <<140, 45, 15, 171, 198, 112, 76, 122, 188, 218, 79, 0, 14, 175, 238, 64, 9, 82, 93, 44,
        169, 176, 237, 27, 115, 221, 101, 211, 5, 168, 169, 235>>

    DBS.map(
      :backward,
      :raw,
      {:or, [["name_claim.account_id": pk], ["name_transfer.recipient_id": pk]]}
    )
  end
end
