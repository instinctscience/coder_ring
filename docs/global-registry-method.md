# Global Registry Method

If your application is running on multiple nodes with Erlang clustering
enabled, you might want the GenServer for a given ring to be running once
across the cluster. (Having multiple simultaneous GenServers for the same
ring will be a bad time.) Here, we'll explain one way to accomplish this.

I recommend the excellent [Horde](https://github.com/derekkraan/horde)
library for this purpose. Follow its documentation to include it as a
dependency, add its supervisor under your application supervisor, etc.

Next, add a line to start the process in `application.exs`:

```elixir
def start do
  children = [...]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  {:ok, pid} = Supervisor.start_link(children, opts)

  MyApp.CoderRing.start_rings()

  {:ok, pid}
end
```

Finally, set up your CoderRing module to look something like this:

```elixir
defmodule MyApp.CoderRing do
  @moduledoc """
  Wraps `CoderRing` functionality in a proc managed by Horde.

  Using a process to hold state means the work is quicker as state-loading
  database queries can be skipped.

  Since it runs under Horde, we are promised to have only one such instance,
  even though each node attempts to start the proc.
  """
  use CoderRing

  @supervisor MyApp.MyHordeSupervisor

  @doc "Start all configured rings."
  @spec start_rings :: :ok
  def start_rings do
    Enum.each(rings(), fn %{name: name} ->
      Horde.DynamicSupervisor.start_child(@supervisor, child_spec(name))
    end)
  end

  @doc false
  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(name) do
    %{
      id: "ring_#{name}",
      start: {__MODULE__, :start_link, [name]}
    }
  end

  @doc """
  Return the `server` pid, first starting it via `child_spec`, if needed.
  """
  @spec find_or_start(GenServer.server(), Supervisor.child_spec(), non_neg_integer) ::
          DynamicSupervisor.on_start_child()
  def find_or_start(name, child_spec) do
    case GenServer.whereis(name) do
      nil -> start_child(child_spec)
      existing_pid -> {:ok, existing_pid}
    end
  end

  @doc """
  Do a call to the ring with the given name. Start it if it isn't running.
  """
  @spec call(any, any) :: any
  def call(name, msg) do
    with {:ok, pid} <- find_or_start(name, child_spec(name)) do
      GenServer.call(pid, msg)
    end
  end

  @impl GenServer
  def init(name) do
    t = :timer.minutes(2)
    {:ok, name |> ring() |> load_memo() |> populate_if_empty(timeout: t)}
  end

  @impl GenServer
  def handle_call(message, _from, state) do
    {reply, state} = invoke(state, message)
    {:reply, reply, state}
  end
end
```

Now, once your application has started, you should be able to get codes from
your global process:

```elixir
iex> MyApp.CoderRing.get_code(:widget)
"8CH4"
iex> MyApp.CoderRing.get_code(:widget)
"GU96"
```