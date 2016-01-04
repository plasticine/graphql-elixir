# Argument values of correct type
#
# A GraphQL document is only valid if all field argument literal values are
# of the type expected by their position.
#
# https://github.com/graphql/graphql-js/blob/master/src/validation/rules/ArgumentsOfCorrectType.js
defmodule GraphQL.Validation.Rules.ArgumentsOfCorrectType do
  alias GraphQL.Validation.Context

  def visitor(_, _) do
    %{
      Argument: fn(%{item: item}) ->
        nil

        # IO.inspect Context.get
        # IO.inspect context
        # IO.inspect context.document
        # IO.inspect context.schema
        # IO.inspect item
      end
    }
  end
end
