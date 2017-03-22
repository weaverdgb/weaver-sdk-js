require("./test-suite")

describe 'WeaverHistory test', ->



  it 'should set a new string attribute', (done)->
    node = new Weaver.Node()

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
      history.getHistory(node.id())
    ).then((response) ->
      console.log(response)
      done()
    )

    return "Hasta la vista, baby"

