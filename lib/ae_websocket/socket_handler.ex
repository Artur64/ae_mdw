defmodule AeWebsocket.SocketHandler do
  use Riverside, otp_app: :ae_mdw

  @known_prefixes ["ak_", "ct_", "ok_", "nm_", "cm_", "ch_"]
  @known_channels ["KeyBlocks", "MicroBlocks", "Transactions"]

  @impl Riverside
  def init(session, state) do
    deliver_me("connected")
    new_state = Map.put(state, :info, [])
    {:ok, session, new_state}
  end

  @impl Riverside
  def handle_message(
        %{
          "op" => "Subscribe",
          "payload" => "Object",
          "target" => <<prefix_key::binary-size(3), _rest::binary-size(50)>> = target
        },
        session,
        %{info: info} = state
      )
      when prefix_key in @known_prefixes do
    id = AeMdw.Validate.id!(target)

    AeMdwWeb.Listener.new_object(id)
    Riverside.LocalDelivery.join_channel(id)

    new_state = %{state | info: (info ++ [target]) |> Enum.uniq()}

    deliver_me(new_state.info)
    {:ok, session, new_state}
  end

  def handle_message(%{"op" => "Subscribe", "payload" => payload}, session, %{info: info} = state)
      when payload in @known_channels do
    Riverside.LocalDelivery.join_channel(payload)
    new_state = %{state | info: (info ++ [payload]) |> Enum.uniq()}
    deliver_me(new_state.info)
    {:ok, session, new_state}
  end

  def handle_message(
        %{"op" => "Unsubscribe", "payload" => "Object", "target" => target},
        session,
        %{info: info} = state
      ) do
    AeMdwWeb.Listener.remove_object(target)
    Riverside.LocalDelivery.leave_channel(target)
    new_state = %{state | info: info -- [target]}
    deliver_me(new_state.info)
    {:ok, session, new_state}
  end

  def handle_message(
        %{"op" => "Unsubscribe", "payload" => payload},
        session,
        %{info: info} = state
      ) do
    Riverside.LocalDelivery.leave_channel(payload)
    new_state = %{state | info: info -- [payload]}

    deliver_me(new_state.info)
    {:ok, session, new_state}
  end

  def handle_message(%{"op" => "Subscribe", "payload" => payload}, session, %{info: info} = state) do
    new_state = %{state | info: (info ++ [payload]) |> Enum.uniq()}
    deliver_me(new_state.info)
    {:ok, session, new_state}
  end

  def handle_message(_msg, session, state), do: {:ok, session, state}



  @impl Riverside
  def handle_info(into, session, state) do
    {:ok, session, state}
  end

  @impl Riverside
  def terminate(reason, session, state) do
    :ok
  end
end
