require("./test-suite")

describe 'WeaverModel', ->

  it 'should build a simple model', ->

    rockModel = new Weaver.Model("RockModel")
    rockModel.structure({
      origin: "@hasOrigin"
      age: "hasAge"
    })
    assert.equal(rockModel.attributes.definition, '{"origin":"@hasOrigin","age":"hasAge"}')


  it 'should save a simple model', (done)->

    rockModel = new Weaver.Model("RockModel")
    rockModel.structure({
      origin: "@hasOrigin"
      age: "hasAge"
    }).save().then(->

      rockModelId = rockModel.id()
      rockModel = null

      Weaver.Node.load(rockModelId).then((rockMod)->
        assert.equal(rockMod.attributes.definition, '{"origin":"@hasOrigin","age":"hasAge"}')
        done()
      )
    )
    return

  it 'should build a model with a static attribute', (done)->

    rockModel = new Weaver.Model("RockModel")
    rockModel.structure({
      origin: "@hasOrigin"
      age: "hasAge"
    })
    .setStatic("age", "Really damn old.")

    Rock = rockModel.buildClass()
    mrRock = new Rock()
    mrRock.get("age").then((res)->
      assert.equal(res, "Really damn old.")
      mrRock.save()
      done()
    )
    return

  it 'should save a model with a static attribute', (done)->

    rockModel = new Weaver.Model("RockModel")
    rockModel.structure({
      origin: "@hasOrigin"
      age: "hasAge"
    })
    .setStatic("age", "Really damn old.")
    .save().then(->

      rockModelId = rockModel.id()
      rockModel = null

      Weaver.Node.load(rockModelId).then((node)->

#      console.log(rockMod) # supplying a constructor to Weaver.Node.load() seems to be failing
        rockMod = new Weaver.Model(node.id())
        rockMod._loadFromQuery(node)
        Rock = rockMod.buildClass()
        mrRock = new Rock()
        mrRock.get("age").then((res)->
          assert.equal(res, "Really damn old.")
          done()
        )
      )
    )
    return

  it 'should build a model with a static relation', (done)->

    canada = new Weaver.Node('Canada')
    canada.save()

    rockModel = new Weaver.Model("RockModel")
    rockModel.structure({
      origin: "@hasOrigin"
      age: "hasAge"
    })
    .setStatic("origin", canada)

    Rock = rockModel.buildClass()
    mrRock = new Rock()
    mrRock.save()
    mrRock.get("origin").then((res)->
      assert.equal(res[0].id(), 'Canada')
      done()
    )
    return

  it 'should save a model with a static relation', (done)->

    canada = new Weaver.Node('Canada')
    canada.save()

    rockModel = new Weaver.Model("RockModel")
    rockModel.structure({
      origin: "@hasOrigin"
      age: "hasAge"
    })
    .setStatic("origin", canada)
    .save().then(->

      rockModelId = rockModel.id()
      rockModel = null

      Weaver.Node.load(rockModelId).then((node)->

#      console.log(rockMod) # supplying a constructor to Weaver.Node.load() seems to be failing
        rockMod = new Weaver.Model(node.id())
        rockMod._loadFromQuery(node)

        Rock = rockMod.buildClass()
        mrRock = new Rock()
        mrRock.get("origin").then((res)->
          assert.equal(res[0].id(), 'Canada')
          done()
        )
      )
    )
    return

  it 'should support deep "get" calls', (done)->

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
              mrRock = new Rock()
              mrRock.get("origin.name").then((res)->
                assert.notEqual(res.indexOf('Canada'), -1)
                assert.notEqual(res.indexOf('Ireland'), -1)
                assert.equal(res.indexOf('Netherlands'), -1)
                done()
              )
            )
          )
        )
      )
    )
    return


  #  it 'should make a requirement model', (done)->
  #
  #    # Create type models & instances
  #    typeModel = new Weaver.Model("Type")
  #    typeModel.structure({
  #      name:"hasLabel"
  #    })
  #    .save()
  #    Type = typeModel.buildClass()
  #    myRequirementType = new Type('Requirement')
  #    myRequirementType.setProp('name', 'The Requirement Type')
  #    .save()
  #
  #    myDescriptionType = new Type('Description')
  #    myDescriptionType.setProp('name', 'The Description Type')
  #    .save().then(->
  #
  #      # Create description model & instance
  #      descModel = new Weaver.Model("Description")
  #      descModel.structure(
  #        type: "@hasType"
  #        text: "hasText"
  #      )
  #      .setStatic("type", myDescriptionType)
  #      .setStatic("text", 'Test description')
  #
  #      descModel.save().then(->
  #
  #        Description = descModel.buildClass()
  #        myDescription = new Description()
  #        myDescription.save()
  #
  #        # Create requirement model & instance
  #        reqModel = new Weaver.Model("Requirement")
  #        reqModel.structure(
  #          type: "@hasType"
  #          name: "hasName"
  #          description: "@hasDescription"
  #          descriptionText: ["description", "text"]
  #        )
  #        .setStatic("type", myRequirementType)
  #        reqModel.save()
  #        Requirement = reqModel.buildClass()
  #
  #        r1 = new Requirement("idR1")
  #        r1.setProp("name", "Test requirement")
  #        .setProp("description", myDescription)
  #        .save().then(->
  #
  #          # Test!
  #          assert.equal(r1.get('name'), 'Test requirement')
  #
  #          reqType = r1.get('type')[0]
  #          assert.equal(reqType.get('name'), 'The Requirement Type')
  #
  #          d1 = r1.get('description')[0]
  #
  #          assert.equal(d1.get('text'), 'Test description')
  #          assert.equal(d1.get('text'), r1.get('descriptionText'))
  #
  #          descType = d1.get('type')[0]
  #          assert.equal(descType.get('name'), 'The Description Type')
  #
  #          # Inline instantiation
  #          r2 = new Requirement('idR2')
  #          r2.setProp("name", "Whatever requirement")
  #          .setProp("description", new Description())
  #          .save().then(->
  #
  #            assert.equal(r2.get('type')[0].id(), 'Requirement')
  #            assert.equal(r2.get('description.type')[0].id(), 'Description')
  #            assert.equal(r2.get('description.type.name'), 'The Description Type')
  #            done()
  #          )
  #        )
  #      )
  #    )
  #    return
