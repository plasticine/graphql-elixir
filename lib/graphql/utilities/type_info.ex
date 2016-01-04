defmodule GraphQL.Utilities.TypeInfo do
  def enter(schema, item) do
    case item.kind do
      :SelectionSet        -> "SelectionSet"
      :Field               -> "Field"
      :Directive           -> "Directive"
      :OperationDefinition -> "OperationDefinition"
      :InlineFragment      -> "InlineFragment"
      :FragmentDefinition  -> "FragmentDefinition"
      :VariableDefinition  -> "VariableDefinition"
      :Argument            -> "Argument"
      :List                -> "List"
      :ObjectField         -> "ObjectField"
      _                    -> nil
    end
  end

  def leave(schema, item) do
    case item.kind do
      :SelectionSet        -> "SelectionSet"
      :Field               -> "Field"
      :Directive           -> "Directive"
      :OperationDefinition -> "OperationDefinition"
      :InlineFragment      -> "InlineFragment"
      :FragmentDefinition  -> "FragmentDefinition"
      :VariableDefinition  -> "VariableDefinition"
      :Argument            -> "Argument"
      :List                -> "List"
      :ObjectField         -> "ObjectField"
      _                    -> nil
    end
  end
end
