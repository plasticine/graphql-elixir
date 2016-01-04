defmodule GraphQL.Validation.Context do
  use GenServer

  defstruct errors: [], type_info: %{}

  def start_link(schema, document) do
    GenServer.start_link(__MODULE__, [schema, document, %__MODULE__{}])
  end

  # def argument(pid), do: GenServer.call(pid, :argument)
  def errors(pid), do: GenServer.call(pid, :errors)
  def error(pid, error), do: GenServer.call(pid, {:error, error})
  def type_info(pid, info), do: GenServer.call(pid, {:type_info, info})

  # GenServer callbacks
  def init(schema, document, context) do
    {:ok, [schema, document, context]}
  end

  def handle_call(:errors, _, state = [_, _, context]) do
    case Enum.any?(context.errors) do
      true  -> {:reply, {:error, context.errors}, state}
      false -> {:reply, {:ok, context.errors}, state}
    end
  end

  def handle_call({:error, error}, _, [schema, document, context]) do
    context = %__MODULE__{context | errors: [error | context.errors]}
    {:reply, context, [schema, document, context]}
  end

  def handle_call({:type_info, type_info}, _, [schema, document, context]) do
    context =  %__MODULE__{context | type_info: type_info}
    {:reply, context, [schema, document, context]}
  end
end
