defmodule WebsocketHandler do
  @behaviour :cowboy_websocket
  
  def init(req, state) do
    IO.puts "websocket connection"
    :erlang.start_timer(1000, self, [])
    {:cowboy_websocket, req, state}
  end

  def terminate do
    :ok
  end

  def websocket_handle({:text, content}, state) do
    {:ok, message} = Poison.decode(content)
    inspect(message) |> IO.puts
    {:reply, {:text, "received"}, state}
  end

  def websocket_handle(_frame, _req, state) do
    {:ok, state}
  end

  def websocket_info({_timeout, _ref, _msg}, req, state) do
    {:reply, {:text, "Hi there"}, req, state}
  end

  def websocket_info(_info, _req, state) do
    {:ok, state}
  end
end
