weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

describe 'WeaverNode test', ->
  it 'should handle concurrent remove node operations', ->
    a = new Weaver.Node()

    a.save().then(->
      Promise.all([a.destroy(), a.destroy()])
    )

  it 'should reject loading undefined nodes', ->
    new Weaver.Node().save().then( ->
      Weaver.Node.load(undefined)
    ).should.eventually.be.rejected

  it 'should reject loading unexistant nodes', ->
    Weaver.Node.load('doesnt-exist')
    .should.eventually.be.rejected


  it 'should reject setting an id attribute', ->
    a = new Weaver.Node()
    expect(-> a.set('id', 'idea')).to.throw()

  it 'should reject forcing an id attribute', ->
    a = new Weaver.Node()
    a.set('placeholder', 'totally-not-id')
    writeOp = i for i in a.pendingWrites when i.action is 'create-attribute'
    writeOp.key = 'id'
    expect(a.save()).to.be.rejected

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

    a.relation('2link').add(b)
    c.relation('2link').add(c) # Is this right? or should it be b.relation('2link').add(c) ?
    wipeCurrentProject().then(->
      Promise.all([a.save(), c.save()])
    ).then(->
      b.destroy()
    ).then(->
      new Weaver.Query()
      .withRelations()
      .hasNoRelationIn('2link')
      .hasNoRelationOut('2link')
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
    id = node.id()

    node.save().then((node) ->
      node.destroy()
    ).then(->
      Weaver.Node.load(id)
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

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

  it 'should set a new string attribute with special datatype', ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('url', 'http://www.yahoo.com/bean', 'xsd:anyURI')
      assert.equal(node.get('url'), 'http://www.yahoo.com/bean')

      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('url'), 'http://www.yahoo.com/bean')
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

  it 'should increment an existing out-of-sync number attribute', ->
    # weaver.setOptions({ignoresOutOfDate: false})
    node = new Weaver.Node()
    sameNode = undefined
    node.set('length', 3)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('length'), 3)
      sameNode = loadedNode
      node.increment('length', 4)
    ).then((value) ->
      assert.equal(value, 7)
      sameNode.increment('length', 5)
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('length'), 12)
    )

  # This test is written to make sure it's possible to save a node after a out-of-sync increment where an error has been caught.
  it 'should increment an existing out-of-sync number attribute and be able to save afterwards', ->
    node = new Weaver.Node()
    sameNode = undefined
    node.set('length', 3)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('length'), 3)
      sameNode = loadedNode
      node.increment('length', 4)
    ).then((value) ->
      assert.equal(value, 7)
      sameNode.increment('length', 5)
    ).then(->
      sameNode.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('length'), 12)
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

  it 'should give an error if node already exists', ->
    node1 = new Weaver.Node('double-node')
    node2 = new Weaver.Node('double-node')

    node1.save().then(->
      node2.save()
    ).then(->
      assert(false)
    ).should.be.rejectedWith('The id double-node already exists')

  it 'should give an error if node does not exist', ->
    Weaver.Node.load('lol').then((res) ->
      assert(false)
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

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
      expect(a).to.have.property('_stored').be.equal(true)
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

  it 'should clone a node', ->
    a = new Weaver.Node('clonea')
    b = new Weaver.Node('cloneb')
    c = new Weaver.Node('clonec')
    cloned = null

    a.set('name', 'Foo')
    b.set('name', 'Bar')
    c.set('name', 'Dear')

    a.relation('to').add(b)
    b.relation('to').add(c)
    c.relation('to').add(a)

    Weaver.Node.batchSave([a,b,c])
    .then(->
      a.clone('cloned-a')
    ).then( ->
      Weaver.Node.load('cloned-a')
    ).then((cloned) ->
      assert.notEqual(cloned.id(), a.id())
      assert.equal(cloned.get('name'), 'Foo')
      to = value for key, value of cloned.relation('to').nodes
      assert.equal(to.id(), b.id())
      Weaver.Node.load(c.id())
    ).then((node) ->
      assert.isDefined(node.relation('to').nodes['cloned-a'])
    )

  it 'should recursively clone a node', ->
    foo = new Weaver.Node('foo')
    bar = new Weaver.Node('bar')

    foo.relation('baz').add(bar)

    foo.save().then(->
      foo.clone('new-foo', 'baz')
    ).then(->
      Weaver.Node.load('new-foo')
    ).then((newFoo) ->
      expect(newFoo.relation('baz').nodes).to.not.have.property('bar')
    )

  it 'should clone loops', ->
    paper = new Weaver.Node('paper')
    sissors = new Weaver.Node('sissors')
    rock = new Weaver.Node('rock')

    paper.relation('beats').add(rock)
    rock.relation('beats').add(sissors)
    sissors.relation('beats').add(paper)

    paper.save().then(->
      paper.clone('new-paper', 'beats')
    )

  it 'should clone links to loops', ->
    paper = new Weaver.Node('2paper')
    sissors = new Weaver.Node('2sissors')
    rock = new Weaver.Node('2rock')

    player = new Weaver.Node('2player')

    paper.relation('beats').add(rock)
    rock.relation('beats').add(sissors)
    sissors.relation('beats').add(paper)
    player.relation('chooses').add(sissors)

    player.save().then(->
      paper.clone('2new-paper', 'beats')
    ).then(->
      Weaver.Node.load('2player')
    ).then((pl) ->
      expect(pl.relation('chooses').all()).to.have.length.be(2)
      expect(pl.relation('chooses').nodes).to.have.property('2sissors')
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
    Weaver.Node.firstOrCreate('firstOrCreate')
      .then((node) ->
        assert.isTrue(node._stored)
        assert.equal(node.id(), 'firstOrCreate')
      )

  it 'should not create a node return the existing node if it already exist', ->
    new Weaver.Node('firstOrCreateExists').save()
      .then((node) ->
        assert.isTrue(node._stored)
        Weaver.Node.firstOrCreate('firstOrCreateExists')
      ).then((node) ->
        assert.isTrue(node._stored)
        assert.isTrue(node._loaded)
        assert.equal(node.id(), 'firstOrCreateExists')
      )

  it 'should be possible to get write operations from a node when weaver is not instantiated', ->
    instance = Weaver.instance
    Weaver.instance = undefined
    try

      node = new Weaver.Node('jim')
      node.set('has', 'beans')

      operations = node.peekPendingWrites()
      expect(operations).to.have.length(2)
    finally
      Weaver.instance = instance

  it 'should reject interaction with out-of-date nodes when ignoresOutOfDate is false', ->
    weaver.setOptions({ignoresOutOfDate: false})
    a = new Weaver.Node() # a node is created and saved at some point
    a.set('name','a')
    ay = {}
    aay = {}

    a.save().then(->
      Weaver.Node.load(a.id()) # node is loaded and assigned to some view variable at some point
    ).then((res)->
      ay = res
      Weaver.Node.load(a.id()) # node is loaded and assigned to some other view variable at some point (inside a separate component, most likely)
    ).then((res)->
      aay = res
      ay.set('name','Aq') # user changed the name to 'Aq'
      aay.set('name','A') # at some point in the future, a user saw the result, recognized the typo, and decided to change the name back to 'A'
      Promise.all([
        ay.save(),
        aay.save()
      ])
    ).finally(->
      weaver.setOptions({ignoresOutOfDate: true})
    ).should.eventually.be.rejected

  it 'should not reject interaction with out-of-date nodes by default', ->
    a = new Weaver.Node() # a node is created and saved at some point
    a.set('name','a')
    ay = {}
    aay = {}

    a.save().then(->
      Weaver.Node.load(a.id()) # node is loaded and assigned to some view variable at some point
    ).then((res)->
      ay = res
      Weaver.Node.load(a.id()) # node is loaded and assigned to some other view variable at some point (inside a separate component, most likely)
    ).then((res)->
      aay = res
      ay.set('name','Aq') # user changed the name to 'Aq'
      aay.set('name','A') # at some point in the future, a user saw the result, recognized the typo, and decided to change the name back to 'A'
      Promise.all([
        ay.save(),
        aay.save()
      ])
    )

  it 'should handle concurrent saves from multiple references, when the ignoresOutOfDate flag is passed', ->
    weaver.setOptions({ignoresOutOfDate: true})
    a = new Weaver.Node() # a node is created and saved at some point
    a.set('name','a')
    ay = {}
    aay = {}

    a.save().then(->  # :: USE CASE ::
      Weaver.Node.load(a.id())                       # node is loaded and assigned to some view variable at some point
    ).then((res)->
      ay = res
      Weaver.Node.load(a.id())                       # node is loaded and assigned to some other view variable at some point (inside a separate component, most likely)
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
      Weaver.Node.load(a.id())
    ).then((res)->
      assert.equal(res.get('name'),'_A')
      res.set('name','A_')
      res.save()
    ).then((res)->
      assert.equal(res.get('name'),'A_')
    ).then(->
      ay.set('name', 'Ay')
      aay.set('name','Aay')
      Promise.all([ay.save(), aay.save()])
    ).finally(->
      weaver.setOptions({ignoresOutOfDate: false})
    )

  it 'should reject out-of-sync attribute updates by default', ->
    a = new Weaver.Node()
    a.set('name', 'first')
    alsoA = undefined

    a.save().then(->
      Weaver.Node.load(a.id())
    ).then((node) ->
      alsoA = node
      a.set('name', 'second')
      a.save()
    ).then(->
      alsoA.set('name', 'allegedly updates first')
      alsoA.save()
    ).should.be.rejectedWith('The attribute that you are trying to update is out of synchronization with the database, therefore it wasn\'t saved')

  it 'should allow out-of-sync attribute updates if the ignoresOutOfDate flag is set', ->
    weaver.setOptions({ignoresOutOfDate: true})
    a = new Weaver.Node()
    a.set('name', 'first')
    alsoA = undefined

    a.save().then(->
      Weaver.Node.load(a.id())
    ).then((node) ->
      alsoA = node
      a.set('name', 'second')
      a.save()
    ).then(->
      alsoA.set('name', 'allegedly updates first')
      alsoA.save()
    ).finally(->
      weaver.setOptions({ignoresOutOfDate: false})
    )

  it 'should reject out-of-sync relation updates by default', ->
    a = new Weaver.Node()
    alsoA = undefined
    b = new Weaver.Node()
    c = new Weaver.Node()
    d = new Weaver.Node()
    a.relation('rel').add(b)

    Weaver.Node.batchSave([a, b, c, d]).then(->
      Weaver.Node.load(a.id())
    ).then((node) ->
      alsoA = node
      a.relation('rel').update(b, c)
      a.save()
    ).then(->
      alsoA.relation('rel').update(b, d)
      alsoA.save()
    ).should.be.rejectedWith('The relation that you are trying to update is out of synchronization with the database, therefore it wasn\'t saved')

  it 'should allow out-of-sync relation updates if the ignoresOutOfDate flag is set', ->
    weaver.setOptions({ignoresOutOfDate: true})
    a = new Weaver.Node()
    alsoA = undefined
    b = new Weaver.Node()
    c = new Weaver.Node()
    d = new Weaver.Node()
    a.relation('rel').add(b)

    Weaver.Node.batchSave([a, b, c, d]).then(->
      Weaver.Node.load(a.id())
    ).then((node) ->
      alsoA = node
      a.relation('rel').update(b, c)
      a.save()
    ).then(->
      alsoA.relation('rel').update(b, d)
      alsoA.save()
    ).finally(->
      weaver.setOptions({ignoresOutOfDate: false})
    )

  it 'should fail trying to save a node with the same id than the destroyed node', ->
    a = new Weaver.Node('theid')
    a.save()
    .then( ->
      a.destroy()
    ).then( ->
      new Weaver.Node('theid').save()
    ).should.be.rejectedWith('The id theid already exists')

  it 'should fail trying to save a node saved with another attribute value', ->
    a = new Weaver.Node('theid')
    a.set('name','Toshio').save()
    .then( ->
      Weaver.Node.load('theid')
    ).then((loadedNode) ->
      loadedNode.set('name','Samantha')
      loadedNode.save()
    ).should.be.rejectedWith('The id theid already exists')


  it 'should allow to override the out-of-sync attribute updates at the set operation if the ignoresOutOfDate flag is set', ->
    weaver.setOptions({ignoresOutOfDate: true})
    a = new Weaver.Node()
    a.set('name', 'first')
    alsoA = undefined
    options = {ignoresOutOfDate: true}
    a.save().then(->
      Weaver.Node.load(a.id())
    ).then((node) ->
      alsoA = node
      a.set('name', 'second', null,options)    # checking for the existence of the ignoresOutOfDate parameter so any value passed here will overrides the {ignoresOutOfDate: true} state
      a.save()
    ).then(->
      alsoA.set('name', 'allegedly updates first', null,options)
      alsoA.save()
    ).finally(->
      false
      weaver.setOptions({ignoresOutOfDate: false})
    ).should.be.rejectedWith('The attribute that you are trying to update is out of synchronization with the database, therefore it wasn\'t saved')

  it 'should execute normally with a small amount of operations', ->
    weaver.setOptions({ignoresOutOfDate: true})
    a = new Weaver.Node()
    alsoA = undefined
    b = new Weaver.Node()
    c = new Weaver.Node()
    d = new Weaver.Node()
    a.relation('rel').add(b)

    Weaver.Node.batchSave([a, b, c, d]).then(->
      Weaver.Node.load(a.id())
    ).then((node) ->
      alsoA = node
      a.relation('rel').update(b, c)
      a.save()
    ).then(->
      alsoA.relation('rel').update(b, d)
      alsoA.save()
    ).finally(->
      weaver.setOptions({ignoresOutOfDate: false})
    )

  it 'should execute per batch with a high amount of operations', ->
    ###
    In this test there is still a low amount of operations, but the batchsize is reduced to 2.
    This test will have 9 operations which lead to 5 batches (4x2 + 1x1)
    Same test as it 'should clone a node', but with reduced batchsize.
    ###

    cm = Weaver.getCoreManager()
    cm.maxBatchSize = 2
    a = new Weaver.Node('clonea2')
    b = new Weaver.Node('cloneb2')
    c = new Weaver.Node('clonec2')
    cloned = null

    a.set('name', 'Foo')
    b.set('name', 'Bar')
    c.set('name', 'Dear')

    a.relation('to').add(b)
    b.relation('to').add(c)
    c.relation('to').add(a)

    Weaver.Node.batchSave([a,b,c])
    .then(->
      a.clone('cloned-a2')
    ).then( ->
      Weaver.Node.load('cloned-a2')
    ).then((cloned) ->
      assert.notEqual(cloned.id(), a.id())
      assert.equal(cloned.get('name'), 'Foo')
      to = value for key, value of cloned.relation('to').nodes
      assert.equal(to.id(), b.id())
      Weaver.Node.load(c.id())
    ).then((node) ->
      assert.isDefined(node.relation('to').nodes['cloned-a2'])
    )

  it 'should batch delete nodes', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()

    Weaver.Node.batchSave([a,b,c])
    .then( ->
      expect(a).to.have.property('_stored').be.equal(true)
      Weaver.Node.load(a.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), a.id())
    ).then( ->
      Weaver.Node.load(b.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), b.id())
    ).then( ->
      Weaver.Node.load(c.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), c.id())
    ).then( ->
      Weaver.Node.batchDestroy([a,b,c])
    ).then( ->
      Weaver.Node.load(a.id())
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
    ).then( ->
      Weaver.Node.load(b.id())
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
    ).then( ->
      Weaver.Node.load(c.id())
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
    )

  it 'should handler an error when trying batch delete nodes with any node', ->

    Weaver.Node.batchDestroy()
    .catch((error)->
      assert.equal(error, "Cannot batch destroy nodes without any node")
    )

  it 'should reject when trying batch delete nodes without proper nodes', ->
    a = new Weaver.Node()
    b = 'lol'
    c = undefined
    Weaver.Node.batchDestroy([a,b,c])
    .should.eventually.be.rejected

  it 'should not crash on destroyed relation nodes', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    a.relation('link').add(b)
    a.save().then(->
      b.destroy()
    ).then(->
      a.set('anything','x')
      a.save()
    ).should.not.be.rejected

  it 'should not be able to recreate a node after deleting it', -> # Fix when error codes are working properly
    node1 = new Weaver.Node('double-node')
    node2 = new Weaver.Node('double-node')

    node1.save().then((node) ->
      node1.destroy()
    ).then(->
      node2.save()
    ).catch((error) ->
      # assert.equal(error.code, Weaver.Error.NODE_ALREADY_EXISTS) #Expected
      assert.equal(error.code, Weaver.Error.WRITE_OPERATION_INVALID) #Actual
    )

  it 'should be able to recreate a node after deleting it unrecoverable', ->
    weaver.setOptions({unrecoverableRemove: true})
    node1 = new Weaver.Node('double-node1')
    node2 = new Weaver.Node('double-node1')
    id = node1.id()
    node1.save().then(->
      node1.destroy()
    ).then(->
      node2.save()
    ).then(->
      Weaver.Node.load(node2.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), id)
    ).then(->
    ).catch((error)->
      console.log(error)
    )
    .finally( ->
      weaver.setOptions({unrecoverableRemove: false})
    )

  it 'should be possible to get write operations from a node when weaver is not instantiated', ->
    instance = Weaver.instance
    Weaver.instance = undefined
    try

      node = new Weaver.Node('jim')
      node.set('has', 'beans')

      operations = node.peekPendingWrites()
      expect(operations).to.have.length(2)
    finally
      Weaver.instance = instance



  it 'should be able to delete a node unrecoverable by setting it as a parameter', ->
    node = new Weaver.Node()
    id = node.id()
    node.save().then(->
      node.destroy(null, true)
    ).then(->
      Weaver.Node.load(id)
    ).catch((error) ->
      # Error.code isn't fully working on this one, should have its own code. Node not found is working if node is in the removed_node table
      # Node should not exist at all, not even in the garbage can.
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
    )

  it 'should be able to delete a node unrecoverable', ->
    weaver.setOptions({unrecoverableRemove: true})
    node = new Weaver.Node()
    id = node.id()
    node.save().then(->
      node.destroy()
    ).then(->
      Weaver.Node.load(id)
    ).catch((error) ->
      # Error.code isn't fully working on this one, should have its own code. Node not found is working if node is in the removed_node table
      # Node should not exist at all, not even in the garbage can.
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
    ).finally( ->
      weaver.setOptions({unrecoverableRemove: false})
    )

  it 'should be able to remove a node with attributes and relations unrecoverable', ->
    weaver.setOptions({unrecoverableRemove: true})
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()
    a.relation('link').add(b)
    b.relation('link').add(c)
    a.set('number', 50)
    a.set('value', 100)
    a.set('value', 200)

    a.save().then( ->
      a.relation('link').update(b, c)
      a.save()
      c.save()
    ).then(->
      a.destroy()
    ).then(->
      Weaver.Node.load(b.id())
    ).catch((error) ->
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND) # Error.code isn't fully working on this one, should have its own code. Node not found is working if node is in the deleted table
      # Node should not exist at all, not even in the garbage can.
    ).finally(
      weaver.setOptions({unrecoverableRemove: false})
    )

  it.skip 'should add graph options to nodes', -> #Final test
    node = new Weaver.Node(cuid(), 'first-graph')
    node.relation('link', 'second-graph').add(target)
    node.set('age', 41, 'third-graph')
    node.save().then( ->
      Weaver.Node.load(node.id())
    ).then((result) ->
      expect(result.graph).to.be.defined()
    )
