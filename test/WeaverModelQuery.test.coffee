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
    recreateRocksAndCountries().then(->
      quarryModel = new Weaver.Model("QuarryModel")
      quarryModel.structure({
        contains: ["@hasRock", 'RockModel']
        rockOrigin: "contains.origin"
        rockOriginName: ""
      })
      .setStatic('contains', new Weaver.Node('Rock'))
      .save().then(->
        Quarry = quarryModel.buildClass()
        myQuarry = new Quarry()
        myQuarry.save().then(->

          Weaver.Node.load("QuarryModel").then((node)->

            quarryMod = new Weaver.Model(node.id())
            quarryMod._loadFromQuery(node)

            modelQ = new Weaver.ModelQuery()
            modelQ.applyModel(quarryMod)
            modelQ.executeQuery()
          ).then((res)->
            promises = []
            promises.push(r.get('rockOriginName')) for r in res
            Promise.all(promises)
          ).then((res)->
            console.log(res)
          )
        )
      )
    )

  recreateRocksAndCountries = ()->

    ###
      THIS CALLS THE SAME CODE AS THE 'should support deep "get" calls' TEST
    ###
    countryType = new Weaver.Node('Country')
    countryType.save().then(->
      countryModel = new Weaver.Model("CountryModel")
      countryModel.structure({
        type: "@hasType"
        name: "hasLabel"
      })
      .setStatic("type", countryType)
      .save().then(->

        Country = countryModel.buildClass()
        canada = new Country("Canada")
        canada.setProp('name', 'Canada')
        canada.save().then(->

          ireland = new Country("Ireland")
          ireland.setProp('name', 'Ireland')
          ireland.save().then(->

            rockModel = new Weaver.Model("RockModel")
            rockModel.structure({
              origin: ["@hasOrigin", countryModel.id()]
              age: "hasAge"
              originName: "origin.name"
            })
            .setStatic("origin", canada)
            .setStatic("origin", ireland)
            .save().then(->

              canada = null
              countryModel = null

              Rock = rockModel.buildClass()
              mrRock = new Rock('Rock')
              mrRock.save().then(->
                Promise.resolve()
              )
            )
          )
        )
      )
    )

