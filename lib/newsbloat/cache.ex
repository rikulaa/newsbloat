defmodule Newsbloat.Cache do
  use GenServer

  @cache __MODULE__

  @doc """
  Starts the the simple 'key-value' cache
  """
  def start_link(opts) do
    GenServer.start_link(@cache, :ok, opts)
  end

  def ensure_fresh({_key, value, %{ timestamp: timestamp, ttl: ttl }}) do
    cond do
      abs(DateTime.diff(timestamp, DateTime.utc_now())) < ttl ->
        {:ok, value}
      true -> 
        {:error, []}
    end
  end

  def get(key) do
   # 2. Lookup is now done directly in ETS, without accessing the server
    case :ets.lookup(@cache, key) do
      [row] -> ensure_fresh(row)
      [] -> {:error, []}
    end
  end

  @doc """
  Inser 'key' to the cache. 
  TTL is in seconds.
  """
  def insert(key, value, ttl \\ 60) do
    GenServer.cast(@cache, {:insert, key, value, %{ timestamp: DateTime.utc_now(), ttl: ttl }})
  end

  @doc """
  Resets the whole cache
  """
  def reset() do
    GenServer.cast(@cache, {:reset})
  end

  ## Defining GenServer Callbacks
  @impl true
  def init(:ok) do
     ets_table = :ets.new(@cache, [:named_table, read_concurrency: true])
    {:ok, ets_table}
  end

  # @impl true
  # def handle_call({:get, key}, ets_table, _state) do
  #   {:reply, Map.fetch(cache, key), cache}
  # end

  @impl true
  def handle_cast({:insert, key, value, ttl}, ets_table) do
    :ets.insert(ets_table, {key, value, ttl})
    {:noreply, ets_table}
  end
  @impl true

  def handle_cast({:reset}, ets_table) do
    :ets.delete_all_objects(ets_table)
    {:noreply, ets_table}
  end

end
