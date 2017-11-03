weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')
cuid   = require('cuid')

describe 'Events test', ->

  it 'should listen for new created nodes', (done) ->
    id = cuid()

    Weaver.subscribe('node.created', (msg, node) ->
      expect(msg).to.equal("node.created")
      expect(node.id()).to.equal(id)
      Weaver.clearAllSubscriptions()

      done()
    )

    new Weaver.Node(id)


  it 'should unsubscribe for new created nodes', (done) ->
    cb = sinon.spy()
    token = Weaver.subscribe('node.created', cb)

    Weaver.unsubscribe(token)
    new Weaver.Node()

    setTimeout(->
      expect(cb.called).to.equal(false);
      done()
    , 100)


  it 'should listen for saved nodes', (done) ->
    id = cuid()

    Weaver.subscribe('node.saved', (msg, node) ->
      expect(msg).to.equal("node.saved")
      expect(node.id()).to.equal(id)

      Weaver.clearAllSubscriptions()
      done()
    )

    new Weaver.Node(id).save()
    return


  it 'should listen for loaded nodes', (done) ->
    id = cuid()

    Weaver.subscribe('node.loaded', (msg, node) ->
      expect(msg).to.equal("node.loaded")
      expect(node.id()).to.equal(id)

      Weaver.clearAllSubscriptions()
      done()
    )

    new Weaver.Node(id).save()
    Weaver.Node.load(id)
    return


  it 'should listen for destroyed nodes', (done) ->
    id = cuid()

    Weaver.subscribe('node.destroyed', (msg, nodeId) ->
      expect(msg).to.equal("node.destroyed")
      expect(nodeId).to.equal(id)

      Weaver.clearAllSubscriptions()
      done()
    )

    node = new Weaver.Node(id)
    node.save().then(->
      Weaver.Node.load(id)
    ).then((loadedNode) ->
      loadedNode.destroy()
    )
    return


  it 'should listen to node attribute set', (done) ->
    id = cuid()

    Weaver.subscribe('node.attribute.set', (msg, data) ->
      expect(msg).to.equal("node.attribute.set")
      expect(data.node.id()).to.equal(id)
      expect(data.field).to.equal("name")
      expect(data.value).to.equal("John")

      Weaver.clearAllSubscriptions()
      done()
    )

    n = new Weaver.Node(id)
    n.set('name', "John")


  it 'should listen to node attribute update', (done) ->
    id = cuid()

    Weaver.subscribe('node.attribute.update', (msg, data) ->
      expect(msg).to.equal("node.attribute.update")
      expect(data.node.id()).to.equal(id)
      expect(data.field).to.equal("name")
      expect(data.value).to.equal("Max")
      expect(data.oldValue).to.equal("John")

      Weaver.clearAllSubscriptions()
      done()
    )

    n = new Weaver.Node(id)
    n.set('name', "John")
    n.set('name', "Max")


  it 'should listen to node attribute unset', (done) ->
    id = cuid()

    Weaver.subscribe('node.attribute.unset', (msg, data) ->
      expect(msg).to.equal("node.attribute.unset")
      expect(data.node.id()).to.equal(id)
      expect(data.field).to.equal("name")

      Weaver.clearAllSubscriptions()
      done()
    )

    n = new Weaver.Node(id)
    n.set('name', "John")
    n.unset('name')


  it 'should listen to node relation add', (done) ->
    id = cuid()

    Weaver.subscribe('node.relation.add', (msg, data) ->
      expect(msg).to.equal("node.relation.add")
      expect(data.node.id()).to.equal(id)
      expect(data.key).to.equal("hasFriend")
      expect(data.target.id()).to.equal("Max")

      Weaver.clearAllSubscriptions()
      done()
    )

    n = new Weaver.Node(id)
    n.relation('hasFriend').add(new Weaver.Node("Max"))


  it 'should listen to node relation update', (done) ->
    id = cuid()

    Weaver.subscribe('node.relation.update', (msg, data) ->
      expect(msg).to.equal("node.relation.update")
      expect(data.node.id()).to.equal(id)
      expect(data.key).to.equal("hasFriend")
      expect(data.oldTarget.id()).to.equal("Max")
      expect(data.target.id()).to.equal("Jack")

      Weaver.clearAllSubscriptions()
      done()
    )

    n = new Weaver.Node(id)
    n.relation('hasFriend').add(new Weaver.Node("Max"))
    n.relation('hasFriend').update(new Weaver.Node("Max"), new Weaver.Node("Jack"))


  it 'should listen to node relation remove', (done) ->
    id = cuid()

    Weaver.subscribe('node.relation.remove', (msg, data) ->
      expect(msg).to.equal("node.relation.remove")
      expect(data.node.id()).to.equal(id)
      expect(data.key).to.equal("hasFriend")
      expect(data.target.id()).to.equal("John")

      Weaver.clearAllSubscriptions()
      done()
    )

    n = new Weaver.Node(id)
    n.relation('hasFriend').add(new Weaver.Node("John"))
    n.relation('hasFriend').remove(new Weaver.Node("John"))
