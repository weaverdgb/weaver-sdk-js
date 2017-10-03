weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverQuery with Wildcard relations', ->
  tree   = new Weaver.Node()
  garden = new Weaver.Node()
  garden.relation('requires').add(tree)

  before ->
    wipeCurrentProject().then( ->
      Promise.all([tree.save(), garden.save()])
    )

  it 'should support hasRelationOut', ->
    new Weaver.Query()
    .hasRelationOut("*", tree)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )

  it 'should support hasRelationIn', ->
    new Weaver.Query()
    .hasRelationIn("*", garden)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support hasNoRelationOut', ->
    new Weaver.Query()
    .hasNoRelationOut("*", tree)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support hasNoRelationIn', ->
    new Weaver.Query()
    .hasNoRelationIn("*", garden)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )
