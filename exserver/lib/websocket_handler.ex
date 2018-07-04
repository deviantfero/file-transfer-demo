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
    {:ok, %{"uuid" => uuid,
			"type" => type}} = Poison.decode(content)
    cond do
      type == "register" -> handle_register(uuid, state)
      type == "getpeer" -> handle_getpeer(uuid, state)
	  type in ["icecandidate", "offer", "answer"]
        -> forward_content(state, content)
	  true -> {:ok, state}
    end
  end

  def forward_content(state, content) do
	{:ok, %{"uuid" => uuid,
			"type" => type,
			"content" => data}} = Poison.decode(content)

	IO.puts "handling #{type}"
	{_, sender} = ChatClients.get_clients("busy")
    |> Enum.find(fn {k, _} -> k == uuid end)

	{:ok, payload} = Poison.encode(data)
	send(sender.trg_pid, {:text, payload})
	{:ok, state}
  end

  def handle_getpeer(uuid, state) do
    available_clients = ChatClients.get_clients("available")
    candidates = Enum.filter(available_clients, fn {k, _} -> k != uuid end)

    {c_uuid, callee} = candidates |> Enum.random
    {_, caller} = available_clients |> Enum.find(fn {k, _} -> k == uuid end)

    ChatClients.assign_target(uuid, callee[:pid])
    ChatClients.assign_target(c_uuid, caller[:pid])
    Enum.each([uuid, c_uuid], &ChatClients.mark_client_as(&1, "busy"))

    {:ok, response} = Poison.encode(%{
      "peersAvailable" => ChatClients.get_client_count("available")
    })

    IO.inspect ChatClients.get_clients("busy")
    ChatClients.broadcast_message(response)
    {:ok, state}
  end

  def handle_register(uuid, state) do
    IO.puts uuid <> " joined the party"
    ChatClients.put_client(uuid,
      %{pid: self(), status: "available", trg_pid: nil})

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
