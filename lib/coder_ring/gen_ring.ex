defmodule CoderRing.GenRing do
  @moduledoc """
  GenServer wrapper for a CoderRing.

  Keeping memo state in memory with a process means some database reads can
  be skipped. State is, however, always synced to the database so it can be
  restored properly on app restart.

  Take care to only have one GenRing proc running for a ring at any given
  time. For instance, if running on a multi-server deployment, use Erlang's
  clustered mode and a global process registry like
  [Horde](https://github.com/derekkraan/horde) to guarantee no more than one
  proc for a ring across the cluster.

  When running on a single server, it should be sufficient to use GenRing.

  ## Usage

  Create a module in your application:

  ```elixir
  defmodule MyApp.CoderRing do
    use CoderRing.GenRing
  end
  ```

  Then, add it to your application supervisor:

  ```elixir
  def start(_type, _args) do
    children =
      [
        ...
      ] ++
        MyApp.CoderRing.child_specs()

    opts = [...]
    {:ok, pid} = Supervisor.start_link(children, opts)
  end
  ```
  """

  defmacro __using__(_) do
    quote do
      use CoderRing
      use GenServer

      @doc false
      @spec child_spec(atom) :: Supervisor.child_spec()
      def child_spec(name) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [name]}
        }
      end

      @doc "Get a list of child specs for all configured rings."
      @spec child_specs :: [Supervisor.child_spec()]
      def child_specs do
        Enum.map(rings(), &child_spec(&1.name))
      end

      @doc """
      Start a GenServer and quietly ignore it when Horde has already started this
      proc somewhere.
      """
      @spec start_link(atom) :: GenServer.on_start()
      def start_link(name) do
        GenServer.start_link(__MODULE__, name, name: :"#{__MODULE__}_#{name}")
      end

      @impl CoderRing
      def call(name, message) do
        GenServer.call(:"#{__MODULE__}_#{name}", message)
      end

      @impl GenServer
      def init(name) do
        {:ok, name |> ring() |> load_memo() |> populate_if_empty()}
      end

      @impl GenServer
      def handle_call(:stop, _from, state) do
        {:stop, :normal, :ok, state}
      end

      def handle_call(message, _from, state) do
        {reply, state} = invoke(state, message)
        {:reply, reply, state}
      end
    end
  end
end
