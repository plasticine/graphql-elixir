defmodule GraphQL.Validation.Context do
  use GenServer

  alias GraphQL.Utilities.TypeInfo

  defstruct errors: [], type_info: %{}

  # Public API.
  def start_link(schema, document) do
    GenServer.start_link(__MODULE__, [schema, document, %__MODULE__{}])
  end

  def get_state(pid), do: GenServer.call(pid, :get_state)
  def errors(pid), do: GenServer.call(pid, :errors)
  def error(pid, error), do: GenServer.call(pid, {:error, error})
  def type_info(pid, info), do: GenServer.call(pid, {:type_info, info})

  # Visitor callback for handling traversal.
  def visitor(pid, schema) do
    {:ok, type_info} = TypeInfo.start_link  # wut?
    %{
      enter: fn(args) ->
        type_info(pid, TypeInfo.enter(type_info, schema, args.item))
      end,
      leave: fn(args) ->
        type_info(pid, TypeInfo.leave(type_info, schema, args.item))
      end
    }
  end

  # GenServer callbacks
  def init(schema, document, context), do: {:ok, [schema, document, context]}

  def handle_call(:get_state, _, state) do
    {:reply, state, state}
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
