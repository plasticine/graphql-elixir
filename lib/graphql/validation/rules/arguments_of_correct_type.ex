# Argument values of correct type
#
# A GraphQL document is only valid if all field argument literal values are
# of the type expected by their position.
#
# https://github.com/graphql/graphql-js/blob/master/src/validation/rules/ArgumentsOfCorrectType.js
defmodule GraphQL.Validation.Rules.ArgumentsOfCorrectType do
  def validate(context) do
    IO.inspect "GraphQL.Validation.Rules.ArgumentsOfCorrectType"

    # argumentDefintion =
    # argumentAST =

    # argumentDefintion.type, argumentAST.value

    # IO.inspect context.document
    # IO.inspect context.schema
  end
end
