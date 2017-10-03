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
  garden.set('name', 'backyard')
  garden.set('theme', 'forest')

  before ->
    wipeCurrentProject().then( ->
      Promise.all([tree.save(), garden.save()])
    )

  it 'should support wildcard relation hasRelationOut', ->
    new Weaver.Query()
    .hasRelationOut("*", tree)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )

  it 'should support wildcard relation hasRelationIn', ->
    new Weaver.Query()
    .hasRelationIn("*", garden)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support wildcard relation hasNoRelationOut', ->
    new Weaver.Query()
    .hasNoRelationOut("*", tree)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support wildcard relation hasNoRelationIn', ->
    new Weaver.Query()
    .hasNoRelationIn("*", garden)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )

  it 'should support find() after count()', ->
    q = new Weaver.Query()

    q.count().should.eventually.equal(2).then(->
      q.find().should.eventually.have.length.be(2)
    )

  it 'should allow the selecting of attributes', ->
    new Weaver.Query()
    .equalTo('theme', 'forest')
    .select('name').find().then((result) ->
      expect(result).to.have.length.be(1)
      expect(result[0]).to.have.property('attributes').to.have.property('name')
      expect(result[0]).to.have.property('attributes').to.not.have.property('theme')
    )
