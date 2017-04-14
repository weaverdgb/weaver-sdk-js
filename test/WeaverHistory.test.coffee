require("./test-suite")

describe 'WeaverHistory test', ->



  it 'should set a new string attribute', (done)->
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
      nodeB.save()
    ).then(->
      history = new Weaver.History()
      history.getHistory([node, nodeB])
    ).then((response) ->
      history = new Weaver.History()
      history.forUser('admin')
      history.fromDateTime('2017-03-23 12:38')
      history.beforeDateTime('2018-03-23 12:39')
      history.getHistory(node, 'name')
    ).then((response) ->
      done()
    )

    return

  it 'should retrieve 100 lines of history dump', ->
    history = new Weaver.History()
    history.limit(100)
    history.dumpHistory()
    .then((response) ->
      assert.isAtMost(response.length,100)
    )

  it 'should retrieve 2 lines of history for the user admin', ->
    history = new Weaver.History()
    history.limit(2)
    history.forUser('admin')
    history.dumpHistory()
    .then((response) ->
      assert.equal(response.length,2)
      for row in response
        assert.equal(row.user,'admin')
    )
