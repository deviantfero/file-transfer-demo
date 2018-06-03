defmodule Exserver.ChatClients do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc "gets a Map of clients that have {status}"
  def get_clients(status) do
    Agent.get(__MODULE__, &(&1))
    |> Enum.filter(fn {_, v} -> v[:status] == status end)
  end

  @doc "puts an available client into the map"
  def put_client(id, client) do
    Agent.update(__MODULE__, &Map.put_new(&1, id, client))
  end

  @doc "marks client as {status} if not already marked"
  def mark_client_as(uuid, new_status) do
    status = Agent.get(__MODULE__, &Kernel.get_in(&1, [uuid, :status]))
    cond do
      is_nil status -> :no_such_client
      status == new_status -> :status_already_set
      true -> 
        Agent.update(__MODULE__,
	&Kernel.update_in(&1, [uuid, :status], fn _ -> new_status end))
    end
  end

  def assign_target(uuid, pid) do
    Agent.update(__MODULE__,
    &Kernel.update_in(&1, [uuid, :trg_pid], fn _ -> pid end))
  end

  @doc "send a message to all clients connected"
  def broadcast_message(payload) do
    clients = Agent.get(__MODULE__, &(&1))
    Enum.each(clients, fn {_k, v} -> send(v.pid, {:text, payload}) end)
  end

  @doc "get the count of clients with {status}"
  def get_client_count(status) do
    Agent.get(__MODULE__, &Enum.filter(&1, fn {_, v} -> v.status == status end)) 
    |> (fn clients -> length(clients) - 1 end).()
  end
end
