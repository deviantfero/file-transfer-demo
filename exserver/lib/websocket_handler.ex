defmodule WebsocketHandler do
  @behaviour :cowboy_websocket
  alias Exserver.ChatClients
  
  def init(req, state) do
    IO.puts "websocket connection"

    ChatClients.start_link nil
    IO.puts "agent started"

    :erlang.start_timer(1000, self(), [])
    {:cowboy_websocket, req, state}
  end

  def terminate do
    :ok
  end

  def websocket_handle({:text, content}, state) do
    {:ok, %{"uuid" => uuid, "type" => type}} = Poison.decode(content)
    cond do
      type == "register" -> handle_register(uuid, state)
      type == "get_peer" -> assign_peer(uuid, state)
    end
  end

  def assign_peer(uuid, state) do
    caller = Agent.get(__MODULE__, &Map.get_in(&1, [uuid]))
    callee = Agent.get(__MODULE__, &Enum.random(&1))
  end

  def handle_register(uuid, state) do
    IO.puts uuid <> " joined the party"

    ChatClients.put_client uuid, %{pid: self(), status: "available"}

    {:ok, response} = Poison.encode(%{
      "peersAvailable" => ChatClients.get_client_count("available")
    })

    ChatClients.broadcast_message(response)
    {:ok, state}
  end

  def websocket_handle(_frame, _req, state) do
    {:ok, state}
  end

  def websocket_info({:text, msg}, state) do
    {:reply, {:text, msg}, state}
  end

  def websocket_info(_info, _req, state) do
    {:ok, state}
  end
end
