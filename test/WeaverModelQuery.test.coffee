require("./test-suite")

describe 'WeaverModelQuery Test', ->

  it 'should build a simple model', ->

    ireland = new Weaver.Node('Ireland')
    ireland.save()

#    rockModel = new Weaver.Model("RockModel")
#    rockModel.structure({
#      origin: "@hasOrigin"
#      age: "hasAge"
#    })
#    .setStatic("age", "Really damn old.")
#    .setStatic("origin", ireland)
#    rockModel.save()

  it 'should instantiate', ->
    quarryModel = {}
    recreateRocksAndCountries().then(->
      quarType = new Weaver.Node('lib-Quarry')
      quarType.set('name', 'Type node for Quarry')
      quarType.save()
      rock = new Weaver.Node('Rock')
      rock.set('name', 'Mr B. Rock')
      rock.save()
      rock2 = new Weaver.Node('Rock2')
      rock2.set('name', 'Mr P. Rock')
      rock2.save()
      quarryModel = new Weaver.Model("QuarryModel")
      quarryModel.structure({
        contains: ["@hasRock", 'RockModel']
#        rockOrigin: "contains.origin"
        type: '@hasType'
      })
      .setStatic('contains', rock)
      .setStatic('contains', rock2)
      .setStatic('type', quarType)
      .save()
    ).then(->
      Quarry = quarryModel.buildClass()
      myQuarry = new Quarry()
      myQuarry.set('name', 'Mr M. Quarry')
      myQuarry.save()
    ).then(->
        Weaver.Node.load("QuarryModel")
    ).then((node)->

      quarryMod = new Weaver.Model(node.id())
      quarryMod._loadFromQuery(node)

      modelQ = new Weaver.ModelQuery()
      modelQ.applyModel(quarryMod)
      modelQ.executeQuery()
    ).then((res)->
      promises = []
      promises.push(r.get('contains')) for r in res
      Promise.all(promises)
    ).then((res)->
      promises = []
      promises.push(r.get('origin')) for r in res[0]
      Promise.all(promises)
    ).then((res)->
#      console.log(res)
#      console.log(mem.get('type')) for mem in res[0]
#      assert.equal(res[0].length, 2)
    )

#    )

  recreateRocksAndCountries = ()->

    ###
      THIS CALLS THE SAME CODE AS THE 'should support deep "get" calls' TEST
    ###
    countryType = new Weaver.Node('Country')
    countryType.set('name', 'Type node for countries')
    countryType.save().then(->
      countryModel = new Weaver.Model("CountryModel")
      countryModel.structure({
        type: "@hasType"
        name: "hasLabel"
        population: "<hasPopulation>"
      })
      .setStatic("type", countryType)
      .save().then(->

        Country = countryModel.buildClass()
        canada = new Country("Canada")
        canada.setProp('name', 'Canada')
        canada.setProp('population', '31,021,300')
        canada.set('name', 'Canada')
        canada.save().then(->

          ireland = new Country("Ireland")
          ireland.setProp('name', 'Ireland')
          ireland.setProp('population', '4,712,816')
          ireland.set('name', 'Ireland')
          ireland.save().then(->

            rockType = new Weaver.Node('lib-Rock')
            rockType.set('name', 'This is the type node for all rocks.')
            rockType.save().then(->

              rockModel = new Weaver.Model("RockModel")
              rockModel.structure({
                origin: ["@hasOrigin", countryModel.id()]
                age: "hasAge"
                type: "@hasType"
#              originName: "origin.name"
              })
              .setStatic("type", rockType)
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
    )

