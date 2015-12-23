defmodule GraphQL.Lang.Visitor do
  defmodule Stack do
    defstruct previous: nil, index: -1, keys: [], in_list: false
  end

  @query_document_keys %{
    Name: [],
    Document: [:definitions],
    OperationDefinition: [:name, :variableDefinitions, :directives, :selectionSet],
    VariableDefinition: [:variable, :type, :defaultValue],
    Variable: [:name],
    SelectionSet: [:selections],
    Field: [:alias, :name, :arguments, :directives, :selectionSet],
    Argument: [:name, :value],
    FragmentSpread: [:name, :directives],
    InlineFragment: [:typeCondition, :directives, :selectionSet],
    FragmentDefinition: [:name, :typeCondition, :directives, :selectionSet],
    IntValue: [],
    FloatValue: [],
    StringValue: [],
    BooleanValue: [],
    EnumValue: [],
    ListValue: [:values],
    ObjectValue: [:fields],
    ObjectField: [:name, :value],
    Directive: [:name, :arguments],
    NamedType: [:name],
    ListType: [:type],
    NonNullType: [:type],
    ObjectTypeDefinition: [:name, :interfaces, :fields],
    FieldDefinition: [:name, :arguments, :type],
    InputValueDefinition: [:name, :type, :defaultValue],
    InterfaceTypeDefinition: [:name, :fields],
    UnionTypeDefinition: [:name, :types],
    ScalarTypeDefinition: [:name],
    EnumTypeDefinition: [:name, :values],
    EnumValueDefinition: [:name],
    InputObjectTypeDefinition: [:name, :fields],
    TypeExtensionDefinition: [:definition]
  }

  def visit(root, visitors) when is_map(visitors) do
    context = %{
      root: root,
      parent: nil,
      keys: get_keys(root),
      in_list: is_list(root),
      index: -1,
      stack: %Stack{},
      visitors: visitors,
      path: [],
      ancestors: [],
    }

    case visit(context) do
      {:ok, result} -> {:ok, result}
    end
  end

  defp visit(%{stack: nil}), do: {:ok, "RESULT!"}
  defp visit(context) when is_map(context) do
    %{
      root: root, parent: parent, keys: keys, in_list: in_list, index: index,
      stack: stack, visitors: visitors, path: path, ancestors: ancestors
    } = context

    index = index + 1
    leaving = index === length(keys)

    if leaving do
      node = parent
      {key, path} = {List.last(path), Enum.drop(path, -1)}

      {parent, ancestors} = cond do
        length(ancestors) == 0 -> {nil, []}
        true                   -> {List.last(ancestors), Enum.drop(ancestors, -1)}
      end

      %{index: index, keys: keys, in_list: in_list, previous: stack} = stack
    else
      {node, key} = cond do
        not is_nil(parent) and in_list     -> {Enum.at(parent, index), index}
        not is_nil(parent) and not in_list -> {Dict.get(parent, Enum.at(keys, index)), Enum.at(keys, index)}
        is_nil(parent)                     -> {root, nil}
        true                               -> {nil, nil}
      end

      if parent && not is_nil(node) do
        path = path ++ [key]
      end
    end

    unless is_nil(node) do
      cond do
        not is_list(node) and is_node(node) ->
          case get_visitor(visitors, node.kind, leaving) do
            {type, visitor} ->
              case visitor.(%{node: node, key: key, parent: parent, path: path, ancestors: ancestors}) do
                %{node: action} -> edit(type, action, node)
                _               -> nil
              end
            nil -> nil
          end
        not is_list(node) -> throw "Invalid AST Node: #{inspect(node)}"
        true -> nil
      end

      unless leaving do
        stack = %Stack{in_list: in_list, index: index, keys: keys, previous: stack}

        in_list = is_list(node)
        if parent do
          ancestors = ancestors ++ [parent]
        end
        keys = get_keys(node)
        index = -1
        parent = node
      end
    end

    visit(%{
      root: root,
      parent: parent,
      keys: keys,
      in_list: in_list,
      index: index,
      stack: stack,
      visitors: visitors,
      path: path,
      ancestors: ancestors
    })
  end

  defp get_keys(node) when is_map(node),  do: Dict.get(@query_document_keys, node.kind, [])
  defp get_keys(node) when is_list(node), do: node
  defp get_keys(_),                       do: []

  defp get_visitor(visitors, kind, true),  do: get_visitor(visitors, kind, :leave)
  defp get_visitor(visitors, kind, false), do: get_visitor(visitors, kind, :enter)
  defp get_visitor(visitors, kind, type) when is_atom(type) do
    cond do
      Map.has_key?(visitors, kind) ->
        nameKey = Map.get(visitors, kind)
        cond do
          is_map(nameKey)                              -> {type, Map.get(nameKey, type)}  # %{Kind: type: fn()}
          is_function(nameKey, 1) and type == :enter -> {type, nameKey} # %{Kind: fn()}
          true                                         -> nil
        end
      Map.has_key?(visitors, type) -> {type, get_in(visitors, [type])} # %{type: fn()}
      true -> nil
    end
  end

  defp is_node(node) do
    is_map(node) and Map.has_key?(node, :kind) and is_atom(node.kind)
  end

  defp edit(type, action, node) when is_atom(type) and is_map(node), do: edit(type, action, node)
  defp edit(:enter, :skip, _node), do: nil                                 # don't visit this node
  defp edit(:enter, :delete, _node), do: nil                               # delete the node
  defp edit(:enter, replacement, _node) when is_map(replacement), do: nil  # replace the node
  defp edit(:leave, :delete, _node), do: nil                               # delete the node
  defp edit(:leave, replacement, _node) when is_map(replacement), do: nil  # replace the node
end
