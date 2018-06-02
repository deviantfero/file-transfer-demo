defmodule Exserver.ChatClients do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc "puts an available client into the map"
  def put_client(id, client) do
    Agent.update(__MODULE__, &Map.put_new(&1, id, client))
  end

  @doc "marks client as {status} if not already marked"
  def mark_client_as(uuid, status) when status == "busy" do
    val = Agent.get(__MODULE__, &Kernel.get_in(&1, [uuid, :status]))
    cond do
      is_nil val -> :no_such_client
      val == status -> :status_already_set
      :true -> 
        Agent.update(__MODULE__, &Kernel.update_in(&1, [uuid, :status], "busy"))
    end
  end

  def broadcast_message(payload) do
    clients = Agent.get(__MODULE__, &(&1))
    Enum.each(clients, fn {_k, v} -> send(v.pid, {:text, payload}) end)
  end


  def get_client_count(status) do
    Agent.get(__MODULE__, &Enum.filter(&1, fn {_k, v} -> v.status == status end)) 
	|> length
  end
end
