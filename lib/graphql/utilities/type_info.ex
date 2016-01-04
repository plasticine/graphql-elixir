defmodule GraphQL.Utilities.TypeInfo do
  use GenServer

  defstruct types: []

  def start_link do
    GenServer.start_link(__MODULE__, %__MODULE__{})
  end

  def enter(pid, _schema, item) do
    operation = case item.kind do
      :SelectionSet        -> :noop
      :Field               -> :noop
      :Directive           -> :noop
      :OperationDefinition -> {:enter, {:OperationDefinition, item}}
      :InlineFragment      -> :noop
      :FragmentDefinition  -> :noop
      :VariableDefinition  -> :noop
      :Argument            -> :noop
      :List                -> :noop
      :ObjectField         -> :noop
      _                    -> :noop
    end
    GenServer.call(pid, operation)
  end

  def leave(pid, _schema, item) do
    operation = case item.kind do
      :SelectionSet        -> :noop
      :Field               -> :noop
      :Directive           -> :noop
      :OperationDefinition -> {:leave, {:OperationDefinition, item}}
      :InlineFragment      -> :noop
      :FragmentDefinition  -> :noop
      :VariableDefinition  -> :noop
      :Argument            -> :noop
      :List                -> :noop
      :ObjectField         -> :noop
      _                    -> :noop
    end
    GenServer.call(pid, operation)
  end

  def init, do: {:ok, %__MODULE__{}}

  # lol
  def handle_call(:noop, _, state), do: {:reply, state, state}

  def handle_call({:enter, {:OperationDefinition, item}}, _, state) do
    type = case item.operation do
      :query        -> :query
      :mutation     -> :mutation
      :subscription -> :subscription
    end
    state = %__MODULE__{state | types: [type | state.types]}
    {:reply, state, state}
  end

  def handle_call({:leave, {:OperationDefinition, item}}, _, state) do
    IO.inspect state
    # state = %__MODULE__{state | types: [type | state.types]}
    {:reply, state, state}
  end
end
