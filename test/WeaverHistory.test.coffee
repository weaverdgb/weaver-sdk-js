weaver = require("./test-suite")
Weaver = weaver.getClass()

describe 'WeaverHistory test', ->



  it 'should set a new string attribute', ->
    node = new Weaver.Node()
    nodeB = new Weaver.Node()

    node.save().then((node) ->
      node.set('name', 'Foo')
      node.save()
    ).then(->
      node.set('name', 'Bar')
      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), 'Bar')
      history = new Weaver.History()
      history.getHistory(node)
    ).then((response) ->
      expect(response).to.have.length.be(3)
      nodeB.save()
    ).then(->
      history = new Weaver.History()
      h = history.getHistory([node, nodeB])
    ).then((response) ->
      expect(response).to.have.length.be(4)
      history = new Weaver.History()
      history.forUser('admin')
      history.fromDateTime('2017-03-23 12:38')
      history.beforeDateTime('2018-03-23 12:39')
      history.getHistory(node, 'name')
    )

  it 'should limit history', ->
    Promise.all((new Weaver.Node()).save() for i in [0..30]).then( ->
      history = new Weaver.History()
      history.limit(20)
      history.dumpHistory()
      .then((response) ->
        expect(response).to.have.length.be(20)
      )
    )

  it 'should retrieve 2 lines of history for the user admin', ->
    Promise.all((new Weaver.Node()).save() for i in [0..1]).then(->
      history = new Weaver.History()
      history.limit(2)
      history.forUser('admin')
      history.dumpHistory()
      .then((response) ->
        assert.equal(response.length,2)
        for row in response
          assert.equal(row.user,'admin')
      )
    )
