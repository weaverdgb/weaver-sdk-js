require("./test-suite")

describe 'WeaverModel', ->

  it 'should make a requirement model', (done)->



    Weaver.connect('http://localhost:9487')

    # Create type models & instances
    typeModel = new Weaver.Model("Type")
    typeModel.structure({
      name:"hasLabel"
    })
    .save()
    Type = typeModel.buildClass()
    myRequirementType = new Type('lib:Requirement')
    myRequirementType.setProp('name', 'The Requirement Type')
    .save()

    myDescriptionType = new Type('lib:Description')
    myDescriptionType.setProp('name', 'The Description Type')
    .save().then(->

      # Create description model & instance
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

        # Create requirement model & instance
        reqModel = new Weaver.Model("Requirement")
        reqModel.structure(
          type: ["hasType", typeModel]
          name: "hasName"
          description: ["hasDescription", descModel]
#          descriptionText: ["text", "description"]
        )
        .equalTo("type", myRequirementType)
        .save()
        Requirement = reqModel.buildClass()

        r1 = new Requirement("idR1")
        r1.setProp("name", "Test requirement")
        .setProp("description", myDescription)
        .save().then(->

          # Test!
          assert.equal(r1.get('name'), 'Test requirement')

          reqType = r1.get('type')[0]
          assert.equal(reqType.get('name'), 'The Requirement Type')

          d1 = r1.get('description')[0]
          assert.equal(d1.get('text'), 'Test description')

          descType = d1.get('type')[0]
          assert.equal(descType.get('name'), 'The Description Type')

          # Inline instantiation
          r2 = new Requirement('idR2')
          r2.setProp("name", "Whatever requirement")
          .setProp("description", new Description())
          .save().then(->

            assert.equal(r2.get('type')[0].id(), 'lib:Requirement')
            assert.equal(r2.get('description.type')[0].id(), 'lib:Description')
            done()
          )

        )


      )
    )
    return
