defmodule GraphQL.Lang.Visitor do
  defmodule Stack do
    defstruct previous: nil, index: -1, keys: [], in_list: false
  end

  @query_document_keys %{
    Name: [],

    Document: ["definitions"],
    OperationDefinition: ["name", "variableDefinitions", "directives", "selectionSet"],
    VariableDefinition: ["variable", "type", "defaultValue"],
    Variable: ["name"],
    SelectionSet: ["selections"],
    Field: ["alias", "name", "arguments", "directives", "selectionSet"],
    Argument: ["name", "value"],

    FragmentSpread: ["name", "directives"],
    InlineFragment: ["typeCondition", "directives", "selectionSet"],
    FragmentDefinition: ["name", "typeCondition", "directives", "selectionSet"],

    IntValue: [],
    FloatValue: [],
    StringValue: [],
    BooleanValue: [],
    EnumValue: [],
    ListValue: ["values"],
    ObjectValue: ["fields"],
    ObjectField: ["name", "value"],

    Directive: ["name", "arguments"],

    NamedType: ["name"],
    ListType: ["type"],
    NonNullType: ["type"],

    ObjectTypeDefinition: ["name", "interfaces", "fields"],
    FieldDefinition: ["name", "arguments", "type"],
    InputValueDefinition: ["name", "type", "defaultValue"],
    InterfaceTypeDefinition: ["name", "fields"],
    UnionTypeDefinition: ["name", "types"],
    ScalarTypeDefinition: ["name"],
    EnumTypeDefinition: ["name", "values"],
    EnumValueDefinition: ["name"],
    InputObjectTypeDefinition: ["name", "fields"],
    TypeExtensionDefinition: ["definition" ]
  }

  def visit(root, visitor = %{}) do
    node = nil
    parent = root
    keys = keys(root)
    in_list = is_list(root)
    index = -1
    stack = %Stack{}
    {:ok, result} = traverse(node, parent, keys, in_list, index, stack, visitor)
  end

  def traverse(_, _, _, _, _, nil, _) do
    {:ok, "RESULT!"}
  end

  def traverse(node, parent, keys, in_list, index, stack, visitor, ancestors \\ {}) do
    index = index + 1
    leaving = index === length(keys)

    if leaving do
      node = parent
      {parent, ancestors} = case tuple_size(ancestors) do
        0    -> {nil, {}}
        size -> {List.last(Tuple.to_list(ancestors)), Tuple.delete_at(ancestors, size - 1)}
      end
      index = stack.index
      keys = stack.keys
      in_list = stack.in_list
      stack = stack.previous
    else
      key = if parent do
        if in_list do
          index
        else
          Enum.at(keys, index)
        end
      else
        nil
      end

      node = if parent do
        if in_list do
          Enum.at(parent, key)
        else
          Dict.get(parent, key)
        end
      else
        parent
      end
    end

    unless is_list(node) do
      unless is_node(node) do
        throw "Invalid AST Node: #{inspect(node)}"
      end
      visitor = get_visitor(visitor, node.kind, leaving)
      if is_function(visitor, 5) do
        path = "foo"
        case visitor.(node, key, parent, path, ancestors) do
          x -> IO.inspect x
        end
      end
    end

    if !is_nil(node) do
      if !leaving do
        stack = %Stack{in_list: in_list, index: index, keys: keys, previous: stack}
        in_list = is_list(node)
        if parent do
          ancestors = Tuple.append(ancestors, parent)
        end
        parent = node
        keys = keys(node)
        index = -1
      end
    end

    traverse(node, parent, keys, in_list, index, stack, visitor, ancestors)
  end

  defp keys(node) when is_map(node),  do: Dict.get(@query_document_keys, node.kind, []) |> Enum.map(&String.to_atom/1)
  defp keys(node) when is_list(node), do: node |> Enum.map(fn(x) -> x.kind end)
  defp keys(_),                       do: []

  defp get_visitor(visitor, kind, leaving) do
    IO.inspect visitor
    IO.inspect kind
    IO.inspect leaving
  end

  defp apply_visitor(visitor, kind, action) do

  end

  defp is_node(node) do
    is_map(node) and Map.has_key?(node, :kind) and is_atom(node.kind)
  end
end
