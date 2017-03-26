require("./test-suite")

describe 'WeaverPlugin test', ->

  it 'should list available plugins', ->
    Weaver.Plugin.list().then((plugins) ->
      console.dir(plugins, {depth: null})
    )
#
#    node.save().then((node) ->
#      Weaver.Node.load(node.id())
#    ).then((loadedNode) ->
#      assert.equal(loadedNode.id(), node.id())
#    ).catch((Err) -> console.log(Err))
#
#
