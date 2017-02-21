require("./test-suite")

describe 'WeaverModelQuery Test', ->

  it 'should build a simple model', ->

    ireland = new Weaver.Node('Ireland')
    ireland.save()

    rockModel = new Weaver.Model("RockModel")
    rockModel.structure({
      origin: "@hasOrigin"
      age: "hasAge"
    })
    .setStatic("age", "Really damn old.")
    .setStatic("origin", ireland)
    rockModel.save()

  it 'should instantiate', ->
    Weaver.Node.load("RockModel").then((node)->

      rockMod = new Weaver.Model(node.id())
      rockMod._loadFromQuery(node)
      console.log(rockMod)
      Rock = rockMod.buildClass()
      new Rock().save().then(->
        modelQ = new Weaver.ModelQuery()
        modelQ.applyModel(rockMod)
        modelQ.executeQuery().then((res)->
          console.log(res)
        )
      )
    )
