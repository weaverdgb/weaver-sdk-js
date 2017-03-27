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
      console.log(response)

      nodeB.save()
    ).then(->

      history = new Weaver.History()
      history.getHistory([node, nodeB])
    ).then((response) ->
      console.log(response)

      history = new Weaver.History()
      history.forUser('admin')
      history.fromDateTime('2017-03-23 12:38')
      history.beforeDateTime('2018-03-23 12:39')
      history.getHistory(node, 'name')
    ).then((response) ->
      console.log(response)
      done()
    )

    return

