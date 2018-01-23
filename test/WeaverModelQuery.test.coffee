weaver  = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver  = require('../src/Weaver')
Promise = require('bluebird')

describe 'WeaverModelQuery test', ->
  model = {}

  before ->
    wipeCurrentProject().then(->
      Weaver.Model.load("test-model", "1.1.0")
    ).then((m) ->
      model = m
      model.bootstrap()
    ).then(->
      person = new model.Person()
      person.set('fullName', 'John Doe')
      person.save()
    )

  it 'should do Weaver.Query on models', ->
    new Weaver.ModelQuery(model)
    .class(model.Person)
    .find()
    .then((instances) ->
      expect(instances).to.have.length.be(1)
      assert.equal(instances[0].constructor, model.Person)
      assert.equal(instances[0].get('fullName'), 'John Doe')
    )

  describe 'with a default model', ->
    before ->
      Weaver.useModel(model)

    it 'should do Weaver.Query from the default currentModel', ->
      assert.equal(model, Weaver.currentModel())

      new Weaver.ModelQuery()
      .class(model.Person)
      .count()
      .then((count) ->
        assert.equal(count, 1)
      )

    describe 'and test data', ->
      before ->
        head    = new model.Head("headA")
        spain   = new model.Country("Spain")
        personA = new model.Person("personA")
        personA.set('fullName', "Aby Delores")
        personB = new model.Person("personB")
        personB.set('fullName', "Gaby Baby")
        personA.relation("hasHead").add(head)
        personB.relation("hasHead").add(head)
        personB.relation("comesFrom").add(spain)

        building = new model.Building()
        area = new model.Area()
        building.relation("placedIn").add(area)
        building.relation("buildBy").add(personA)
        personB.relation("livesIn").add(building)

        Weaver.Node.batchSave([head, spain, personA, personB])

      it 'should do an equalTo WeaverModelQuery', ->
        new Weaver.ModelQuery()
        .equalTo("Person.fullName", "Aby Delores")
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          p = instances[0]

          assert.equal(p.constructor, model.Person)
          assert.equal(p.id(), "personA")
          assert.equal(p.get('fullName'), 'Aby Delores')
          assert.equal(p.relation('hasHead').first().constructor, model.Head)  # <- this fails currently
        )

      it 'should load model instances', ->
        new Weaver.ModelQuery()
          .restrict("personB")
          .first().should.eventually.be.instanceOf(model.Person)

      it 'should load model instances even easier', ->
        model.Person.load("personB").should.eventually.be.instanceOf(model.Person)

      it 'should not error on livesInSomebuilding', ->
        new Weaver.ModelQuery()
        .equalTo("Person.fullName", "Gaby Baby")
        .find()

      it.skip 'handles selectOut correctly', ->
        new Weaver.ModelQuery()
          .restrict("personB")
          .selectOut("Person.livesIn", "Building.placedBy")
          .find()
          # This needs a check to see that the area is loaded

      it 'translates selectOut correctly (whitebox testing)', ->
        q = new Weaver.ModelQuery()
          .restrict("personB")
          .selectOut("Person.livesIn", "Building.placedBy")

        expect(q).to.have.property('_selectOut').to.have.length.be(1)
        expect(q._selectOut[0]).to.have.length.be(2)

      it 'should do a hasRelationIn WeaverModelQuery', ->
        new Weaver.ModelQuery()
        .hasRelationIn("Person.someRelation")
        .find()
        .then((instances) ->
          assert.equal(instances.length, 0)
        )

      it 'should fail on wrong key', ->
        q = new Weaver.ModelQuery()
        assert.throws((-> q.hasRelationIn("someRelation")))
