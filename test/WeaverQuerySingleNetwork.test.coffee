weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverQuery with single Network', ->
  tree   = new Weaver.Node()
  garden = new Weaver.Node()
  garden.relation('requires').add(tree)
  tree.set('testset', '1')
  garden.set('testset', '1')
  road   = new Weaver.Node()
  road.set('testset', '2')
  road.set('name', 'A4')

  before ->
    wipeCurrentProject().then( ->
      Promise.all([tree.save(), garden.save(), road.save()])
    )

  it 'should support wildcard relation hasRelationOut', ->
    new Weaver.Query()
    .hasRelationOut("*", tree)
    .equalTo('testset', '1')
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )

  it 'should support wildcard relation hasRelationIn', ->
    new Weaver.Query()
    .hasRelationIn("*", garden)
    .equalTo('testset', '1')
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support wildcard relation hasNoRelationOut', ->
    new Weaver.Query()
    .hasNoRelationOut("*", tree)
    .equalTo('testset', '1')
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support wildcard relation hasNoRelationIn', ->
    new Weaver.Query()
    .hasNoRelationIn("*", garden)
    .equalTo('testset', '1')
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )

  it 'should support find() after count()', ->
    q = new Weaver.Query()
    .equalTo('testset', '1')

    q.count().should.eventually.equal(2).then(->
      q.find().should.eventually.have.length.be(2)
    )

  it 'should allow the selecting of attributes', ->
    new Weaver.Query()
    .equalTo('testset', '2')
    .select('name').find().then((result) ->
      expect(result).to.have.length.be(1)
    )
