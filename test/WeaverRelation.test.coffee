weaver = require("./test-suite")
Weaver = weaver.getClass()

describe 'WeaverNode relation test', ->

  it 'should add a new relation without id', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()

    console.log("foos id: #{foo.id()}")
    console.log("bars id: #{bar.id()}")

    assert(!foo._loaded)
    assert(!foo._stored)
    assert(!bar._loaded)
    assert(!bar._stored)

    foo.relation('comesBefore').add(bar)
    foo.save().then(->

      console.log(foo.relations['comesBefore'])

      assert(!foo._loaded)
      assert(foo._stored)
      assert(!bar._loaded)
      assert(bar._stored)

      foo.relation('comesBefore').to(bar)

    ).then((rel)->

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

      console.log(loadedNode.relations['comesBefore'])

      loadedNode.relation('comesBefore').to(bar)
#    ).then((loadedRel) ->
#      assert.equal(loadedRel.id(), rel.id())
    )

  it 'should add a new relation with id', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    foo.relation('comesBefore').add(bar, 'abc')

    foo.save().then(->

      Weaver.Node.load('abc')
    ).then((loadedNode) ->

      assert.isDefined(loadedNode)
    )

  it 'should update a relation', ->
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
    foo.relation('comesBefore').add(bar)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      loadedNode.relation('comesBefore').remove(bar)
      loadedNode.save()
    ).then( ->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      relations = (k for k of loadedNode.relations)
      assert.lengthOf(relations, 0)
    )


