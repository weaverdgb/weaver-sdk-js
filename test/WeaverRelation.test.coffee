weaver = require("./test-suite")
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
      assert.isDefined(loadedNode.relation('comesBefore').nodes[bar.id()])

      assert(loadedNode._loaded)
      assert(loadedNode._stored)
      assert(!loadedNode.relation('comesBefore').nodes[bar.id()]._loaded)
      assert(loadedNode.relation('comesBefore').nodes[bar.id()]._stored)

      loadedNode.relation('comesBefore').to(bar)
    ).then((relation) ->
      loadedRel = relation
      assert.isTrue(loadedRel instanceof Weaver.RelationNode)
      assert.equal(loadedRel.id(), rel.id())

# todo: see ticket WEAV-132
#      loadedRel.to()
#    ).then((to) ->
#      assert.isTrue(to instanceof Weaver.Node)
#      assert.equal(to.id(), bar.id())
#
#      loadedRel.from()
#    ).then((from) ->
#      assert.isTrue(from instanceof Weaver.Node)
#      assert.equal(from.id(), foo.id())
    )

  it 'should add a new relation with id', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    foo.relation('comesBefore').add(bar, 'abc')

    foo.save().then(->

      Weaver.Node.load('abc', undefined, undefined, true)
    ).then((loadedNode) ->

      assert.isDefined(loadedNode)
    )

  it.skip 'should update a relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    ono = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').update(bar, ono)

    Weaver.Node.batchSave([foo, bar, ono]).then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      assert.isDefined(loadedNode.relation('comesBefore').nodes[ono.id()])
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
      relations = (k for k of loadedNode.relations)
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
