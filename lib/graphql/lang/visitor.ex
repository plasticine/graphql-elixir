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

  def visit(root, visitors = %{}) do
    parent = root
    keys = keys(root)
    in_list = is_list(root)
    index = -1
    stack = %Stack{}
    {:ok, result} = traverse(parent, keys, in_list, index, stack, visitors)
  end

  # TODO: Yuk
  def traverse(parent, keys, in_list, index, stack, visitors), do: traverse(parent, keys, in_list, index, stack, visitors, {})
  def traverse(_, _, _, _, nil, _, _), do: {:ok, "RESULT!"}
  def traverse(parent, keys, in_list, index, stack, visitors, ancestors) do
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

    if !is_nil(node) do
      unless is_list(node) do
        unless is_node(node) do
          IO.inspect parent
          throw "Invalid AST Node: #{inspect(node)}"
        end
        visitor = visitor(visitors, node.kind, leaving)
        if is_function(visitor, 5) do
          path = "foo"
          visitor.(node, key, parent, path, ancestors)
        end
      end

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

    traverse(parent, keys, in_list, index, stack, visitors, ancestors)
  end

  defp keys(node) when is_map(node),  do: Dict.get(@query_document_keys, node.kind, []) |> Enum.map(&String.to_atom/1)
  defp keys(node) when is_list(node), do: node |> Enum.map(fn(x) -> x.kind end)
  defp keys(_),                       do: []

  defp visitor(visitors, kind, true),  do: visitor(visitors, kind, :leave)
  defp visitor(visitors, kind, false), do: visitor(visitors, kind, :enter)
  defp visitor(visitors, kind, action) when is_atom(action) do
    cond do
      Map.has_key?(visitors, kind) ->
        case Map.get(visitors, kind) do
          name when is_function(name, 5) -> name  # %{Kind: fn()}
          name when is_map(name) -> Map.get(name, action)  # %{Kind: action: fn()}
        end
      Map.has_key?(visitors, action) -> get_in(visitors, [action]) # %{action: fn()}
      true -> nil
    end
  end

  defp is_node(node) do
    is_map(node) and Map.has_key?(node, :kind) and is_atom(node.kind)
  end
end
