weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'Weaver relation and WeaverRelationNode test', ->
  it 'should add a new relation without id', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    rel = null
    loadedRel = null

    assert(!foo._loaded)
    assert(!foo._stored)
    assert(!bar._loaded)
    assert(!bar._stored)

    foo.relation('comesBefore').add(bar)
    foo.save().then(->
      assert(!foo._loaded)
      assert(foo._stored)
      assert(!bar._loaded)
      assert(bar._stored)

      foo.relation('comesBefore').to(bar)
    ).then((relation)->
      rel = relation
      assert.isTrue(rel instanceof Weaver.RelationNode)
      assert.isDefined(rel)
      assert.isDefined(rel.id())

      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      assert.isDefined(loadedNode.relation('comesBefore').nodes.find((x) -> x.equals(bar)))

      assert(loadedNode._loaded)
      assert(loadedNode._stored)
      expect(loadedNode.relation('comesBefore').nodes.find((x) -> x.equals(bar))).to.have.property('_loaded').equal(false)
      assert(loadedNode.relation('comesBefore').nodes.find((x) -> x.equals(bar))._stored)

      loadedNode.relation('comesBefore').to(bar)
    ).then((relation) ->
      loadedRel = relation
      assert.isTrue(loadedRel instanceof Weaver.RelationNode)
      assert.equal(loadedRel.id(), rel.id())
    )

  it 'should add a new relation with id', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    rel = foo.relation('comesBefore').add(bar, 'abc')
    expect(rel).to.be.instanceOf(Weaver.RelationNode)
    foo.save().then(->
      Weaver.Node.load('abc', undefined, undefined, true)
    ).then((loadedNode) ->
      assert.isDefined(loadedNode)
    )


  it 'should save a new relation on relation on node save', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    bass = new Weaver.Node()
    rel = foo.relation('comesBefore').add(bar)
    expect(rel).to.be.instanceOf(Weaver.RelationNode)
    rel.relation('item').add(bass)
    foo.save().then(->
      Weaver.Node.load(rel.id(), undefined, undefined, true)
    ).then((loadedRelNode) ->
      assert.isDefined(loadedRelNode)
      expect(loadedRelNode.relation('item').all()).to.have.length.be(1)
    )

  it 'should update a relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    ono = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    Weaver.Node.batchSave([foo, bar, ono]).then(->
      foo.relation('comesBefore').update(bar, ono)
      foo.save()
    ).then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      expect(loadedNode.relation('comesBefore').nodes.find((x) -> x.equals(ono))).to.be.defined
      expect(loadedNode.relation('comesBefore').nodes.find((x) -> x.equals(bar))).to.not.be.defined
    )

  it 'should remove a relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    zoo = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').add(zoo)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      loadedNode.relation('comesBefore').remove(bar)
      loadedNode.save()
    ).then( ->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      relations = (k for k of loadedNode.relations())
      assert.lengthOf(relations, 1)
    )

  it 'should load all nodes in the relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    ono = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').add(ono)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then(->
      assert.isFalse(node._loaded) for node in foo.relation('comesBefore').all()
      foo.relation('comesBefore').load()
    ).then((nodes) ->
      assert.isTrue(node._loaded) for node in nodes
      assert.isTrue(node._loaded) for node in foo.relation('comesBefore').all()
    )

  it 'should return the first node in a relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    ono = new Weaver.Node()

    assert.isUndefined(foo.relation('comesBefore').first())

    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').add(ono)

    assert.equal(foo.relation('comesBefore').first(), bar)

  describe 'with graphs', ->
    a  = new Weaver.Node('a', 'relationWithGraph1')
    b  = new Weaver.Node('b', 'relationWithGraph1')
    af = new Weaver.Node('a', 'relationWithGraph2')

    b.relation('test').add(a)
# This relation can't be created here because of:
#    http://jira.sysunite.com/browse/WEAV-251
#
#    b.relation('test').add(af)

    before ->
      Weaver.Node.batchSave([a, b, af]).then(->
        b.relation('test').add(af)
        b.save()
      )

    it 'should allow relations to the same node id in different graphs', ->
      expect(Weaver.Node.loadFromGraph('b', 'relationWithGraph1').then((node) ->
        node.relation('test').all()
      )).to.eventually.have.length.be(2)

    it 'should be able to get the relation node for both relations', ->
      Weaver.Node.loadFromGraph('b', 'relationWithGraph1').then((node) ->
        rel = node.relation('test')
        Promise.all([ rel.to(a), rel.to(af) ])
      ).then((res) ->
        expect(res[0].id()).to.not.equal(res[1].id())
      )

