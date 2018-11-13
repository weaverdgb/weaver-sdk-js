moment             = require('moment')
weaver             = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver             = require('../src/Weaver')

describe 'WeaverNode test', ->
  it 'should allow a node to be destroyed', ->
    a = new Weaver.Node('this-is-going-to-be-destroyed')
    a.save().then(->
      a.destroy()
    ).then(->
      Weaver.Node.load('this-is-going-to-be-destroyed')
    ).should.be.rejected

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

  it 'should reject instantiating a node with an existing node id', ->
    a = new Weaver.Node()
    a.save().then(->
      new Weaver.Node(a.id()).save()
    ).should.be.rejected

  it 'should reject setting an id attribute', ->
    a = new Weaver.Node()
    expect(-> a.set('id', 'idea')).to.throw()

  it 'should reject forcing an id attribute', ->
    a = new Weaver.Node()
    a.set('placeholder', 'totally-not-id')
    writeOp = i for i in a._pendingWrites when i.action is 'create-attribute'
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
      assert.isUndefined(res.relations().link)
    )

  it 'should propagate delete to relations (part 2)', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()

    a.relation('2link').add(b)
    relNode = c.relation('2link').add(c)
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
      expect(i.id() for i in res).to.have.members([a.id(), relNode.id()])
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

  it 'should mention id in not found error', ->
    Weaver.Node.load('non:existant')
    .should.eventually.be.rejected.and.has.property('message', 'Node ["non:existant"] not found in [null]')

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

  it 'should set a new string attribute with special datatype uri', ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('url', 'http://www.yahoo.com/bean', 'xsd:anyURI')
      assert.equal(node.get('url'), 'http://www.yahoo.com/bean')
      assert.equal(node.getDataType('url'), 'xsd:anyURI')

      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('url'), 'http://www.yahoo.com/bean')
      assert.equal(loadedNode.getDataType('url'), 'xsd:anyURI')
    )

  it 'should set a new string attribute with special datatype integer', ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('count', 1, 'xsd:integer')
      assert.equal(node.get('count'), 1)
      assert.equal(node.getDataType('count'), 'xsd:integer')

      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('count'), 1)
      assert.equal(loadedNode.getDataType('count'), 'xsd:integer')
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

    node.save().then((node) ->
      node.set('number', 1.2)
      assert.equal(node.getDataType('number'), 'double')

      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('number'), 1.2)
      assert.equal(loadedNode.getDataType('number'), 'double')
    )

  it 'should not allow js Date object for  attribute', ->
    node = new Weaver.Node()
    date = new Date()
    expect(-> node.set('time', date)).to.throw()

  it 'should set a date attribute', ->
    node = new Weaver.Node()
    date = moment()
    node.set('time', date)
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('time')
      assert(moment.isMoment(loadedDate), 'type of loaded attribute value should be moment')
      assert(loadedDate.isSame(date), "the loaded date #{loadedDate.toJSON()} should equal the original date #{date.toJSON()}")
    )

  it 'should set a xsd dateTime attribute', ->
    node = new Weaver.Node()
    date = moment()
    node.set('date', date, 'xsd:dateTime')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('date')
      assert(moment.isMoment(loadedDate), 'type of loaded attribute value should be moment')
      assert(loadedDate.isSame(date), "the loaded date #{loadedDate.toJSON()} should equal the original date #{date.toJSON()}")
    )

  it 'should set a xsd time attribute', ->
    node = new Weaver.Node()
    date = '13:20:00-05:00'
    node.set('time', date, 'xsd:time')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('time')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd date attribute', ->
    node = new Weaver.Node()
    date = '2004-04-12-05:00'
    node.set('date', date, 'xsd:date')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('date')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd gYearMonth attribute', ->
    node = new Weaver.Node()
    date = '2004-04-05:00'
    node.set('g', date, 'xsd:gYearMonth')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('g')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd gYear attribute', ->
    node = new Weaver.Node()
    date = '12004'
    node.set('g', date, 'xsd:gYear')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('g')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd gMonthDay attribute', ->
    node = new Weaver.Node()
    date = '--04-12Z'
    node.set('g', date, 'xsd:gMonthDay')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('g')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd gDay attribute', ->
    node = new Weaver.Node()
    date = '---02'
    node.set('g', date, 'xsd:gDay')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('g')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd gMonth attribute', ->
    node = new Weaver.Node()
    date = '--04-05:00'
    node.set('g', date, 'xsd:gMonth')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('g')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd duration attribute', ->
    node = new Weaver.Node()
    date = 'P2Y6M5DT12H35M30S'
    node.set('duration', date, 'xsd:duration')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('duration')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd dayTimeDuration attribute', ->
    node = new Weaver.Node()
    date = 'P1DT2H'
    node.set('duration', date, 'xsd:dayTimeDuration')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('duration')
      expect(loadedDate).to.equal(date)
    )

  it 'should set a xsd yearMonthDuration attribute', ->
    node = new Weaver.Node()
    date = 'P2Y6M'
    node.set('duration', date, 'xsd:yearMonthDuration')
    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedDate = loadedNode.get('duration')
      expect(loadedDate).to.equal(date)
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

  it 'should allow setting an attribute value again with save', ->
    node = new Weaver.Node()
    node.set('test', 'a')
    node.save().then(->
      node.set('test', 'a')
      node.save()
    )

  it 'should allow setting an attribute value again immediately', ->
    node = new Weaver.Node()
    node.set('test', 'a')
    node.set('test', 'a')
    node.save()

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
    ).should.be.rejectedWith(Weaver.Error.NODE_ALREADY_EXISTS)

  it 'should give an error if node does not exist', ->
    Weaver.Node.load('lol').should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

  it 'should create a relation', ->
    a = new Weaver.Node()
    b = new Weaver.Node()

    a.relation('rel').add(b)

    a.save().then(->
      Weaver.Node.load(a.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.relation('rel').first().id(), b.id())
    )

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
    .then(->
      expect(a).to.have.property('_stored').be.equal(true)
      Weaver.Node.load(a.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), a.id())
    )
    .then(->
      Weaver.Node.load(b.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), b.id())
    )
    .then(->
      Weaver.Node.load(c.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), c.id())
    )

  it 'should clone a node to another graph', ->
    a = new Weaver.Node('original-a')
    b = new Weaver.Node('original-b')
    c = new Weaver.Node('original-c')
    cloned = null

    a.set('name', 'Foo')
    b.set('name', 'Bar')
    c.set('name', 'Dear')

    a.relation('to').add(b)
    b.relation('to').add(c)
    c.relation('to').add(a)

    Weaver.Node.batchSave([a,b,c])
    .then(->
      a.cloneToGraph('cloned-a', 'my-graph')
    ).then( ->
      Weaver.Node.load('cloned-a', undefined, undefined, false, false, 'my-graph')
    ).then((cloned) ->
      assert.notEqual(cloned.id(), a.id())
      assert.equal(cloned.get('name'), 'Foo')
      assert.equal(cloned.getGraph(), 'my-graph')
      to = value for value in cloned.relation('to').all()
      assert.equal(to.id(), b.id())
      Weaver.Node.load(c.id())
    ).then((node) ->
      assert.isDefined(node.relation('to').all().find((x) -> x.equals(Weaver.Node.getFromGraph('cloned-a', 'my-graph'))))
    )

  it 'should clone a node to another graph while using loadFromGraph function', ->
    d = new Weaver.Node('original-d')
    e = new Weaver.Node('original-e')
    f = new Weaver.Node('original-f')
    cloned = null

    d.set('name', 'Foo')
    e.set('name', 'Bar')
    f.set('name', 'Dear')

    d.relation('to').add(e)
    e.relation('to').add(f)
    f.relation('to').add(d)

    Weaver.Node.batchSave([d,e,f])
    .then(->
      d.cloneToGraph('cloned-d', 'my-graph')
    ).then( ->
      Weaver.Node.loadFromGraph('cloned-d', 'my-graph')
    ).then((cloned) ->
      assert.notEqual(cloned.id(), d.id())
      assert.equal(cloned.get('name'), 'Foo')
      assert.equal(cloned.getGraph(), 'my-graph')
      to = value for value in cloned.relation('to').all()
      assert.equal(to.id(), e.id())
      Weaver.Node.load(f.id())
    ).then((node) ->
      assert.isDefined(node.relation('to').all().find((x) -> x.equals(Weaver.Node.getFromGraph('cloned-d', 'my-graph'))))
    )

  it 'should clone a node', ->
    a = new Weaver.Node('original a')
    b = new Weaver.Node('original b')
    c = new Weaver.Node('original c')
    cloned = null

    a.set('name', 'Foo')
    b.set('name', 'Bar')
    c.set('name', 'Dear')

    a.relation('to').add(b)
    b.relation('to').add(c)
    c.relation('to').add(a)

    Weaver.Node.batchSave([a,b,c])
    .then(->
      a.clone('cloned a')
    ).then( ->
      Weaver.Node.load('cloned a')
    ).then((cloned) ->
      assert.notEqual(cloned.id(), a.id())
      assert.equal(cloned.get('name'), 'Foo')
      to = value for value in cloned.relation('to').all()
      assert.equal(to.id(), b.id())
      Weaver.Node.load(c.id())
    ).then((node) ->
      assert.isDefined(node.relation('to').all().find((x) -> x.equals(Weaver.Node.get('cloned a'))))
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
      expect(newFoo.relation('baz').all()).to.not.have.property('bar')
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
      expect(pl.relation('chooses').all().find((x) -> x.equals(Weaver.Node.get('2sissors')))).to.be.defined
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

  it 'should load an incomplete node thats stored in another graph', ->
    incompleteNode = null

    node = new Weaver.Node('a', 'some-graph')
    node.set('name', 'Foo')

    node.save()
    .then(->
      incompleteNode = new Weaver.Node(node.id(), node.getGraph())
      incompleteNode.load()
    ).then(->
      assert.equal(incompleteNode.id(), 'a')
      assert.equal(incompleteNode.getGraph(), 'some-graph')
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
      aay.save()                                  # (it's weird that he would do this in a separate component, but hey, monkey-testing)
    ).then((res)->
      res.set('name','_A')
      res.save()
    ).then(->
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
    ).should.be.rejectedWith(Weaver.Error.WRITE_OPERATION_INVALID)

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
    ).should.be.rejectedWith(Weaver.Error.WRITE_OPERATION_INVALID)

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

  it 'should allow saving a node with the same id as the destroyed node', ->
    a = new Weaver.Node('theid')
    a.save()
    .then( ->
      a.destroy()
    ).then( ->
      new Weaver.Node('theid').save()
    )

  it 'should fail trying to save a node saved with another attribute value', ->
    a = new Weaver.Node('theid')
    a.set('name','Toshio').save()
    .then( ->
      Weaver.Node.load('theid')
    ).then((loadedNode) ->
      loadedNode.set('name','Samantha')
      loadedNode.save()
    ).should.be.rejectedWith(Weaver.Error.NODE_ALREADY_EXISTS)

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
    ).should.be.rejectedWith(Weaver.Error.WRITE_OPERATION_INVALID)

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
      to = value for value in cloned.relation('to').all()
      assert.equal(to.id(), b.id())
      Weaver.Node.load(c.id())
    ).then((node) ->
      assert.isDefined(node.relation('to').all().find((x) -> x.equals(Weaver.Node.get('cloned-a2'))))
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

  it 'should not be able to recreate a node after deleting it', ->
    node1 = new Weaver.Node('double-node')
    node2 = new Weaver.Node('double-node')

    node1.save().then((node) ->
      node1.destroy()
    ).then(->
      node2.save()
    ).should.be.rejectedWith(Weaver.Error.NODE_ALREADY_EXISTS)

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
    ).finally( ->
      weaver.setOptions({unrecoverableRemove: false})
    )

  it 'should be able to delete a node unrecoverable by setting it as a parameter', ->
    node = new Weaver.Node()
    id = node.id()
    node.save().then(->
      node.destroy(null, true)
    ).then(->
      Weaver.Node.load(id)
      # Error.code isn't fully working on this one, should have its own code. Node not found is working if node is in the removed_node table
      # Node should not exist at all, not even in the garbage can.
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

  it 'should be able to delete a node unrecoverable', ->
    weaver.setOptions({unrecoverableRemove: true})
    node = new Weaver.Node()
    id = node.id()
    node.save().then(->
      node.destroy()
    ).then(->
      Weaver.Node.load(id)
    ).finally( ->
      weaver.setOptions({unrecoverableRemove: false})
      # Error.code isn't fully working on this one, should have its own code. Node not found is working if node is in the removed_node table
      # Node should not exist at all, not even in the garbage can.
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

  it 'should be able to remove a node with attributes and relations unrecoverable', ->
    weaver.setOptions({unrecoverableRemove: true})
    a = new Weaver.Node('hi')
    b = new Weaver.Node('hello')
    c = new Weaver.Node('bye')
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
      Weaver.Node.load(a.id())
    ).finally(
      weaver.setOptions({unrecoverableRemove: false})
      # Error.code isn't fully working on this one, should have its own code. Node not found is working if node is in the deleted table
      # Node should not exist at all, not even in the garbage can.
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

  it 'should be able to remove a node and its attributes and relations unrecoverable', ->
    weaver.setOptions({unrecoverableRemove: true})
    a = new Weaver.Node('hi')
    b = new Weaver.Node('hello')
    c = new Weaver.Node('bye')
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
    ).finally(
      weaver.setOptions({unrecoverableRemove: false})
      # Error.code isn't fully working on this one, should have its own code. Node not found is working if node is in the deleted table
      # Node should not exist at all, not even in the garbage can.
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

  it 'should be able to propogate destroy to specified relations', ->
    a = new Weaver.Node('Grandmother')
    b = new Weaver.Node('Mother')
    c = new Weaver.Node('Child')
    a.relation('gaveBirthTo').add(b)
    b.relation('gaveBirthTo').add(c)

    a.save().then(->
      a.destroy(weaver.currentProject().projectId, true, ['gaveBirthTo'], 2)
    ).then(->
      Weaver.Node.load('Child')
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

  it 'should stop propogation at the correct depth', ->
    a = new Weaver.Node('Grandmother')
    b = new Weaver.Node('Mother')
    c = new Weaver.Node('Child')
    a.relation('gaveBirthTo').add(b)
    b.relation('gaveBirthTo').add(c)

    a.save().then(->
      a.destroy(weaver.currentProject().projectId, true, ['gaveBirthTo'])
    ).then(->
      Weaver.Node.load('Child')
    ).then((node)->
      expect(node.id()).to.equal('Child')
      Weaver.Node.load('Mother')
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

  it 'should not propogate destroy to unspecified relations', ->
    a = new Weaver.Node('Grandfather')
    b = new Weaver.Node('Father')
    c = new Weaver.Node('Brother')
    d = new Weaver.Node('Son')

    a.relation('raised').add(b)
    b.relation('raised').add(d)
    b.relation('hasBrother').add(c)

    a.save().then(->
      a.destroy(weaver.currentProject().projectId, true, ['raised'], 2)
    ).then(->
      Weaver.Node.load('Brother')
    ).then((node)->
      expect(node.id()).to.equal('Brother')
    )

  it 'should propogate destroy to specified relations, even when there are also unspecified relations', ->
    a = new Weaver.Node('Grandfather')
    b = new Weaver.Node('Father')
    c = new Weaver.Node('Brother')
    d = new Weaver.Node('Son')

    a.relation('raised').add(b)
    b.relation('raised').add(d)
    b.relation('hasBrother').add(c)

    a.save().then(->
      a.destroy(weaver.currentProject().projectId, true, ['raised'])
    ).then(->
      Weaver.Node.load('Son')
    ).should.be.rejectedWith(Weaver.Error.NODE_NOT_FOUND)

  it 'should add create and remove statements to pendingWrites with graphs', ->
    node = new Weaver.Node('node1', 'first-graph')
    target = new Weaver.Node(null, 'second-graph')
    target2 = new Weaver.Node(null, 'third-graph')
    node.relation('link').add(target)
    node.relation('link').add(target2)
    node.set('age', 41, 'double', null, 'fourth-graph')
    node.set('age', 42, 'double', null, 'fifth-graph')
    node.set('age', 43, 'double')
    node.destroy()
    expect(node._pendingWrites[0].graph).to.equal('first-graph')
    expect(target._pendingWrites[0].graph).to.equal('second-graph')
    expect(target2._pendingWrites[0].graph).to.equal('third-graph')
    expect(node._pendingWrites[1].graph).to.equal('fourth-graph')
    expect(node._pendingWrites[2].graph).to.equal('fifth-graph')
    expect(node._pendingWrites[3].graph).to.equal('first-graph')


  it 'should add collect pending writes when one node is loaded multiple times', ->
    thenode = new Weaver.Node('thenode')
    someother = new Weaver.Node('someother')
    thenode.relation('link').add(someother)
    someother.relation('link').add(thenode)
    Weaver.Node.batchSave([thenode, someother])
    .then(->
      new Weaver.Query()
      .hasRelationOut('link')
      .selectOut('link')
      .find()
    ).then((nodes)->
      thenode1 = null
      thenode2 = null
      for node in nodes
        thenode1 = node if node.id() is 'thenode'
        thenode2 = node.relation('link').first() if node.id() is 'someother'

      thenode1.set('color', 'yellow')
      thenode2.set('location', 'under water')
      thenode1.relation('equals').add(thenode2)
      setAttributes = (op for op in thenode1.peekPendingWrites() when op.action is 'create-attribute' and op.sourceId is 'thenode')
      expect(setAttributes.length).to.equal(2)
    )

  it 'should add graph options to nodes', ->
    node = new Weaver.Node(null, 'first-graph')
    target = new Weaver.Node(null)
    target2 = new Weaver.Node(null, 'second-graph')
    node.relation('link').add(target)
    node.set('age', 41, 'double', null, 'second-graph')
    node.save().then( ->
      Weaver.Node.loadFromGraph(node.id(), 'first-graph')
    ).then((result) ->
      expect(result.graph).to.equal('first-graph')
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

  it 'should retrieve the createdAt field from a node', ->
    node = new Weaver.Node('test-createdAt')

    expect(node.createdAt()).to.be.defined

    node.save().then(->
      Weaver.Node.load('test-createdAt')
    ).then((savedNode) ->
      expect(savedNode.createdAt()).to.be.defined
    )

  it 'should retrieve the createdBy field from a node', ->
    node = new Weaver.Node('test-createdBy')

    expect(node.createdBy()).to.be.defined

    node.save().then(->
      Weaver.Node.load('test-createdBy')
    ).then((savedNode) ->
      expect(savedNode.createdBy()).to.be.defined
    )

  describe 'equals', ->
    check = (node1id, node1graph, node2id, node2graph) ->
      node1 = new Weaver.Node(node1id, node1graph)
      node2 = new Weaver.Node(node2id, node2graph)
      node1.equals(node2)

    it 'should match same ids in default graph', ->
      expect(check('test', undefined, 'test', undefined)).to.be.true

    it 'should not match different ids in default graph', ->
      expect(new Weaver.Node('test').equals(new Weaver.Node('test1'))).to.be.false

    it 'should match same ids in same graph', ->
      expect(new Weaver.Node('test', 'agraph').equals(new Weaver.Node('test', 'agraph'))).to.be.true

    it 'should not match same ids in different graph', ->
      expect(new Weaver.Node('test', 'agraph').equals(new Weaver.Node('test', 'agraph1'))).to.be.false

  describe 'wpath', ->
    n = undefined
    m = undefined
    o = undefined
    p = undefined

    before ->
      o = new Weaver.Node('o')
      p = new Weaver.Node('p')
      m = new Weaver.Node('m')
      m.relation('some').add(o)
      m.relation('some').add(p)
      n = new Weaver.Node('n')
      n.relation('has').add(m)

    it 'should parse an expression', ->
      expect(n.wpath(undefined)).to.be.empty
      expect(n.wpath('')).to.be.empty
      assert.deepEqual(n.wpath('/has/some?b'), [{'b':o},{'b':p}])
      assert.deepEqual(n.wpath('has?a'), [{'a':m}])
      assert.deepEqual(n.wpath('/has?a/some?what'), [{'a':m, 'what':o}, {'a':m, 'what':p}])

    it 'should parse an expression with filters', ->
      assert.deepEqual(n.wpath('/has?a/some[id=o|id=p]?b'), [{'a':m, 'b':o}, {'a':m, 'b':p}])
      assert.deepEqual(n.wpath('/has?a/some[id=o]?b'), [{'a':m, 'b':o}])
      assert.deepEqual(n.wpath('/has?a/some[id=p]?b'), [{'a':m, 'b':p}])
      expect(n.wpath('/has?a/some[id=o&id=p]?b')).to.be.empty

    it 'should apply functions', ->
      n.wpath('/has?a/some?b', (row)->row['a'].relation('yes').add(row['b']))
      assert.deepEqual(m.relation('yes').all(), [o, p])
