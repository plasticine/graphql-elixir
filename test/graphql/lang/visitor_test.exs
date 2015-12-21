defmodule GraphQL.Lang.Visitor.VisitorTest do
  use ExUnit.Case, async: true

  test "WIP" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b, c { a, b, c } }")
    GraphQL.Lang.Visitor.visit(doc, %{})
  end

  test "traverses the tree" do
    visited = {}
    {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b { x }, c }")
    GraphQL.Lang.Visitor.visit(doc, %{
      enter: fn(node, _, _, _, _) ->
        visited = Tuple.append(visited, ['enter', node.kind, node.value])
      end,
      leave: fn(node, _, _, _, _) ->
        visited = Tuple.append(visited, ['leave', node.kind, node.value])
      end
    })

    assert visited == {
      ['enter', 'Document', nil],
      ['enter', 'OperationDefinition', nil],
      ['enter', 'SelectionSet', nil],
      ['enter', 'Field', nil],
      ['enter', 'Name', 'a'],
      ['leave', 'Name', 'a'],
      ['leave', 'Field', nil],
      ['enter', 'Field', nil],
      ['enter', 'Field', nil],
      ['enter', 'Name', 'c'],
      ['leave', 'Name', 'c'],
      ['leave', 'Field', nil],
      ['leave', 'SelectionSet', nil],
      ['leave', 'OperationDefinition', nil],
      ['leave', 'Document', nil],
    }
  end
end
