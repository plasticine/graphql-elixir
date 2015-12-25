# Argument values of correct type
#
# A GraphQL document is only valid if all field argument literal values are
# of the type expected by their position.
#
# https://github.com/graphql/graphql-js/blob/master/src/validation/rules/ArgumentsOfCorrectType.js
defmodule GraphQL.Validation.Rules.ArgumentsOfCorrectType do
  def validate(context) do
    %{
      Argument: fn() ->
        IO.inspect "GraphQL.Validation.Rules.ArgumentsOfCorrectType"

        argumentDefintion = context.getArgument()
        if  argumentDefintion do
          GraphQL.Utilities.is_valid_literal_value(argumentDefintion)
        end

        GraphQL.Lang.Visitor.visit(context.document, %{
          enter: fn(%{node: node}) -> IO.inspect node.kind end
        })
      end
    }
  end
end
