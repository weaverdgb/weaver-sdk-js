weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverQuery with single Network', ->
  tree      = new Weaver.Node()
  garden    = new Weaver.Node()
  statue    = new Weaver.Node()
  ornament  = new Weaver.Node()
  inanimate = new Weaver.Node()
  
  tree.set('testset', '1')
  
  garden.relation('requires').add(tree)
  garden.set('name', 'backyard')
  garden.set('theme', 'forest')
  garden.set('testset', '1')

  statue.set('description', 'something of something')
  statue.set('testset', '2')

  ornament.set('description', 'ornamental')
  ornament.set('objectiveValue', '12')
  ornament.set('testset', '2')

  inanimate.set('description', 'does not move')
  inanimate.set('category', 'cruft')
  inanimate.set('testset', '2')

  statue.relation('isish').add(ornament)
  ornament.relation('isish').add(inanimate)


  before ->
    wipeCurrentProject().then( ->
      Promise.all([statue.save(), garden.save()])
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
    .equalTo('testset', '1')
    .hasNoRelationOut("*", tree)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support wildcard relation hasNoRelationIn', ->
    new Weaver.Query()
    .equalTo('testset', '1')
    .hasNoRelationIn("*", garden)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )

  it 'should support find() after count()', ->
    q = new Weaver.Query().equalTo('testset', '1')

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

  it 'should extend selects to selectOut nodes', ->
    new Weaver.Query()
    .restrict(statue.id())
    .select('description')
    .selectOut('isish').find().then((result)->
      expect(result).to.have.length.be(1)
      expect(result[0]).to.have.property('relations').to.have.property('isish')
      allIsh = result[0].relations.isish.all()
      expect(allIsh).to.have.length.be(1)
      expect(allIsh[0]).to.have.property('attributes').to.have.property('description')
      expect(allIsh[0]).to.have.property('attributes').to.not.have.property('objectiveValue')
    )

  it 'should extend selects to recursive select out nodes', ->
    new Weaver.Query()
    .restrict(statue.id())
    .select('description')
    .selectRecursiveOut('isish').find().then((result)->
      expect(result).to.have.length.be(1)
      expect(result[0]).to.have.property('relations').to.have.property('isish')
      allIsh = result[0].relations.isish.all()
      expect(allIsh).to.have.length.be(1)
      expect(allIsh[0]).to.have.property('attributes').to.have.property('description')
      expect(allIsh[0]).to.have.property('attributes').to.not.have.property('objectiveValue')
      expect(allIsh[0]).to.have.property('relations').to.have.property('isish')
      topAllIsh = result[0].relations.isish.all()
      expect(topAllIsh).to.have.length.be(1)
      expect(topAllIsh[0]).to.have.property('attributes').to.have.property('description')
      expect(topAllIsh[0]).to.have.property('attributes').to.not.have.property('category')

    )

    
