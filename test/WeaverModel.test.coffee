require("./test-suite")

describe 'WeaverModel', ->

  it 'should make a requirement model', ->

    typeModel = new Weaver.Model("Type")

    typeModel.structure({
      name:"hasLabel"
    })
    .save()
    Type = typeModel.buildClass()
    myRequirementType = new Type('lib:Requirement')
    myRequirementType.setProp('name', 'The Requirement Type')
    myRequirementType.save()


    myDescriptionType = new Type('lib:Description')
    myDescriptionType.save().then(->

      descModel = new Weaver.Model("Description")
      descModel.structure(
        type: ["hasType", typeModel]
        text: "hasText"
      )
      .equalTo("type", myDescriptionType)
      .equalTo("text", 'Test description')

      descModel.save().then(->

        Description = descModel.buildClass()
        myDescription = new Description()
        myDescription.save()

        reqModel = new Weaver.Model("Requirement")
        reqModel.structure(
          type: ["hasType", typeModel]
          name: "hasName"
          description: ["hasDescription", descModel]
        )
        .equalTo("type", myRequirementType)
        .save()
        Requirement = reqModel.buildClass()

        r1 = new Requirement("idR1")
        r1.setProp("name", "Test requirement")
        r1.setProp("description", myDescription)
        r1.save().then(->

          assert.equal(r1.get('type')[0].nodeId, 'lib:Requirement')
          assert.equal(r1.get('name'), 'Test requirement')

          d1 = r1.get('description')[0]
          assert.equal(d1.get('type')[0].nodeId, 'lib:Description')
          assert.equal(d1.get('text'), 'Test description')

        )

      )

    )
