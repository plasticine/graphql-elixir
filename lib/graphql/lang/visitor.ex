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

  # Depth-first traversal through the tree.
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
      ancestors: []
    }

    case visit(context) do
      {:ok, result} -> {:ok, result}
    end
  end

  defp visit(%{stack: nil, root: root}), do: {:ok, root}
  defp visit(context) when is_map(context) do
    %{
      root: root, parent: parent, keys: keys, in_list: in_list, index: index,
      stack: stack, visitors: visitors, path: path, ancestors: ancestors
    } = context

    index = index + 1
    leaving = index === length(keys)

    if leaving do
      item = parent
      {key, path} = {List.last(path), Enum.drop(path, -1)}

      {parent, ancestors} = cond do
        length(ancestors) == 0 -> {nil, []}
        true                   -> {List.last(ancestors), Enum.drop(ancestors, -1)}
      end

      %{index: index, keys: keys, in_list: in_list, previous: stack} = stack
    else
      {item, key} = cond do
        not is_nil(parent) and in_list     -> {Enum.at(parent, index), index}
        not is_nil(parent) and not in_list -> {Dict.get(parent, Enum.at(keys, index)), Enum.at(keys, index)}
        is_nil(parent)                     -> {root, nil}
        true                               -> {nil, nil}
      end

      if parent && not is_nil(item) do
        path = path ++ [key]
      end
    end

    unless is_nil(item) do
      cond do
        not is_list(item) and is_item(item) ->
          case get_visitor(visitors, item.kind, leaving) do
            {type, visitor} ->
              case visitor.(%{item: item, key: key, parent: parent, path: path, ancestors: ancestors}) do
                %{item: action} -> edit(type, action, item)
                _               -> nil
              end
            nil -> nil
          end
        not is_list(item) -> throw "Invalid AST Node: #{inspect(item)}"
        true -> nil
      end

      unless leaving do
        stack = %Stack{in_list: in_list, index: index, keys: keys, previous: stack}
        in_list = is_list(item)
        if parent do
          ancestors = ancestors ++ [parent]
        end
        keys = get_keys(item)
        index = -1
        parent = item
      end
    end

    visit(%{root: root, parent: parent, keys: keys, in_list: in_list, index: index,
            stack: stack, visitors: visitors, path: path, ancestors: ancestors})
  end

  defp get_keys(item) when is_map(item),  do: Dict.get(@query_document_keys, item.kind, [])
  defp get_keys(item) when is_list(item), do: item
  defp get_keys(_),                       do: []

  defp get_visitor(visitors, kind, true),  do: get_visitor(visitors, kind, :leave)
  defp get_visitor(visitors, kind, false), do: get_visitor(visitors, kind, :enter)
  defp get_visitor(visitors, kind, type) do
    # this is pretty gross
    cond do
      Map.has_key?(visitors, kind) ->
        name_key = Map.get(visitors, kind)
        cond do
          is_map(name_key)                            -> {type, Map.get(name_key, type)}  # %{Kind: type: fn()}
          is_function(name_key, 1) and type == :enter -> {type, name_key} # %{Kind: fn()}
          true -> nil
        end
      Map.has_key?(visitors, type) -> {type, get_in(visitors, [type])} # %{type: fn()}
      true -> nil
    end
  end

  defp is_item(item) do
    is_map(item) and Map.has_key?(item, :kind) and is_atom(item.kind)
  end

  defp edit(type, action, item) when is_atom(type) and is_map(item), do: edit(type, action, item)
  defp edit(:enter, :skip, _item), do: nil                                 # don't visit this item
  defp edit(:enter, :delete, _item), do: nil                               # delete the item
  defp edit(:enter, replacement, _item) when is_map(replacement), do: nil  # replace the item
  defp edit(:leave, :delete, _item), do: nil                               # delete the item
  defp edit(:leave, replacement, _item) when is_map(replacement), do: nil  # replace the item
end
