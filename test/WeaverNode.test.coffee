weaver = require("./test-suite")
Weaver = require('../src/Weaver')

describe 'WeaverNode test', ->

  it 'should handle concurrent remove node operations', ->
    a = new Weaver.Node()

    a.save().then(->
      Promise.all([a.destroy(), a.destroy()])
    )


  it 'should propagate delete to relations (part 1)', ->
    a = new Weaver.Node()
    b = new Weaver.Node()

    a.relation('link').add(b)
    a.save().then(->
      b.destroy()
    ).then(->
      Weaver.Node.load(a)
    ).then((res)->
      assert.isUndefined(res.relations.link)
    )


  it 'should propagate delete to relations (part 2)', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()

    a.relation('link').add(b)
    c.relation('link').add(c)
    Promise.all([a.save(), c.save()]).then(->
      b.destroy()
    ).then(->
      new Weaver.Query()
      .withRelations()
      .hasNoRelationIn('link')
      .hasNoRelationOut('link')
      .find()
    ).then((res)->
      assert.equal(res.length, 2)
    )


  it 'should create a new node', ->
    node = new Weaver.Node()
    assert(!node._loaded)
    assert(!node._stored)

    node.save().then((node) ->
      assert(!node._loaded)
      assert(node._stored)

      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert(loadedNode._loaded)
      assert(loadedNode._stored)
      assert.equal(loadedNode.id(), node.id())

      Weaver.Node.get(node.id())
    ).then((getNode) ->
      assert(!getNode._loaded)
      assert(!getNode._stored)

    )

  it 'should remove a node', ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.destroy()
    ).then(->
      Weaver.Node.load(node.id())
    ).catch((error) ->
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
    )

  it 'should set a new string attribute', ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('name', 'Foo')
      assert.equal(node.get('name'), 'Foo')

      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), 'Foo')
    )

  it 'should update a string attribute', ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('name', 'Foo')
      node.set('name', 'Bar')
      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), 'Bar')
    )

  it 'should set a new boolean attribute', ->
    node = new Weaver.Node()
    node.set('isBar', false)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('isBar'), false)
    )

  it 'should set a new number attribute', ->
    node = new Weaver.Node()
    node.set('length', 3)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('length'), 3)
    )

  it 'should set a date attribute', ->
    node = new Weaver.Node()
    date = new Date()
    node.set('time', date)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('time').toJSON(), date.toJSON())
    )

  it 'should increment an existing number attribute', ->
    node = new Weaver.Node()
    node.set('length', 3)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('length'), 3)
      node.increment('length', 2)
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('length'), 5)
    )

  it 'should set a new number double attribute', ->
    node = new Weaver.Node()
    node.set('halved', 1.5)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('halved'), 1.5)
    )

  it 'should unset an attribute', ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('name', 'Foo')
      node.save()
    ).then(->
      node.unset('name')
      assert.equal(node.get('name'), undefined)
      node.save()
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), undefined)

      # Reload
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), undefined)
    )

  it 'should set an existing attribute with new value', ->
    node = new Weaver.Node()
    node.set('name', 'Foo')

    node.save().then((node) ->
      node.set('name', 'Bar')
      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), 'Bar')
    )

  it.skip 'should give an error if node already exists', ->
    node1 = new Weaver.Node('a')
    node2 = new Weaver.Node('a')

    node1.save().then(->
      node2.save()
    ).then(->
      assert(false)
    ).catch((error) ->
      assert.equal(error.code, Weaver.Error.NODE_ALREADY_EXISTS)
    )

  it 'should give an error if node does not exist', ->
    Weaver.Node.load('lol').then((res) ->
      assert(false)
    ).catch((error) ->
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
    )

  it 'should create a relation', ->
    a = new Weaver.Node()
    b = new Weaver.Node()

    a.relation('rel').add(b)

    a.save().then(->
      Weaver.Node.load(a.id())
    ).should.eventually.have.property('relations')
        .with.property('rel')
        .with.property('nodes')

  it 'should not blow up when saving in circular chain', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()

    a.relation('to').add(b)
    b.relation('to').add(c)
    c.relation('to').add(a)

    a.save()

  it 'should batch store nodes', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()

    Weaver.Node.batchSave([a,b,c])
    .then(() ->
      Weaver.Node.load(a.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), a.id())
    )
    .then(() ->
      Weaver.Node.load(b.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), b.id())
    )
    .then(() ->
      Weaver.Node.load(c.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), c.id())
    )

  it.skip 'should clone a node', ->

    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()
    cloned = null

    a.set('name', 'Foo')
    b.set('name', 'Bar')
    c.set('name', 'Dear')

    a.relation('to').add(b)
    b.relation('to').add(c)
    c.relation('to').add(a)

    Weaver.Node.batchSave([a,b,c])
    .then(->
      Weaver.Node.load(a.id())
    ).then((node) ->
      node.clone()
    ).then((node) ->
      cloned = node

      assert.notEqual(cloned.id(), a.id())
      assert.equal(cloned.get('name'), 'Foo')
      to = value for key, value of cloned.relation('to').nodes
      assert.equal(to.id(), b.id())

      Weaver.Node.load(c.id())
    ).then((node) ->
      assert.isDefined(node.relation('to').nodes[cloned.id()])
    )


  it 'should load an incomplete node', ->
    incompleteNode = null

    node = new Weaver.Node()
    node.set('name', 'Foo')

    node.save()
    .then(->
      incompleteNode = new Weaver.Node(node.id())
      incompleteNode.load()
    ).then(->
      assert.equal(incompleteNode.get('name'), 'Foo')
    )

  it 'should create and return a node if it doesn\'t exist', ->
    Weaver.Node.firstOrCreate('test')
      .then((node) ->
        assert.isTrue(node._stored)
        assert.equal(node.id(), 'test')
      )

  it 'should not create a node return the existing node if it already exist', ->
    new Weaver.Node('test').save()
      .then((node) ->
        assert.isTrue(node._stored)
        Weaver.Node.firstOrCreate('test')
      ).then((node) ->
        assert.isTrue(node._stored)
        assert.isTrue(node._loaded)
        assert.equal(node.id(), 'test')
      )

  it.skip 'should recursively clone a node', ->

    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()
    cloned = null

    a.set('name', 'Foo')
    b.set('name', 'Bar')
    c.set('name', 'Dear')

    a.relation('to').add(b)
    b.relation('to').add(c)
    c.relation('to').add(a)

    Weaver.Node.batchSave([a,b,c])
    .then(->
      Weaver.Node.load(a.id())
    ).then((node) ->
      node.clone({'to':Weaver.Node})
    ).then((node) ->
      cloned = node

      assert.notEqual(cloned.id(), a.id())
      assert.equal(cloned.get('name'), 'Foo')
      to = value for key, value of cloned.relation('to').nodes
      assert.notEqual(to.id(), b.id())

      Weaver.Node.load(c.id())
    ).then((node) ->
      assert.isDefined(node.relation('to').nodes[cloned.id()])
    )

  it 'should handle concurrent saves from multiple references, when the flag is passed', ->
    weaver.setOptions({ignoresOutOfDate: true})
    a = new Weaver.Node('a') # a node is created and saved at some point
    a.set('name','a')
    ay = {}
    aay = {}

    a.save().then(->  # :: USE CASE ::
      Weaver.Node.load('a')                       # node is loaded and assigned to some view variable at some point
    ).then((res)->
      ay = res
      Weaver.Node.load('a')                       # node is loaded and assigned to some other view variable at some point (inside a separate component, most likely)
    ).then((res)->
      aay = res
      ay.set('name','Ay')                         # user changed the name to 'Ay'
      ay.save()
      aay.set('name','A')                         # at some point in the future, a user saw the result, recognized the typo, and decided to change the name back to 'A'
      aay.save()     # (it's weird that he would do this in a separate component, but hey, monkey-testing)
    ).then((res)->
      res.set('name','_A')
      res.save()
    ).then(()->
      Weaver.Node.load('a')
    ).then((res)->
      assert.equal(res.get('name'),'_A')
      res.set('name','A_')
      res.save()
    ).then((res)->
      assert.equal(res.get('name'),'A_')
    ).then(->
      ay.set('name', 'Ay')
      ay.save()
      aay.set('name','Aay')
      aay.save()
    )
