weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')
cuid   = require('cuid')

describe 'WeaverModel test', ->

  it 'should load in a model from the server', ->
    Weaver.Model.load("test-model", "1.0.0").then((Model) ->
      assert.equal(Model.definition.name,    "test-model")
      assert.equal(Model.definition.version, "1.0.0")
    )


  it 'should fail on a not existing model', ->
    Weaver.Model.load("ghost-model", "1.0.0").then((Model) ->
      assert(false)
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.MODEL_NOT_FOUND)
    )


  it 'should fail on a not existing version of an existing model', ->
    Weaver.Model.load("test-model", "1.0.1").then((Model) ->
      assert(false)
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.MODEL_VERSION_NOT_FOUND)
    )


  describe 'with a loaded model', ->
    model = {}

    before ->
      Weaver.Model.load("test-model", "1.0.0").then((m) ->
        model = m
      )

    it 'should set the type definition to the model class', ->
      Person = model.Person
      person = new Person()
      assert.equal(person.relation("_proto").first().id(), "#{model.definition.name}:#{person.className}")


    it 'should set attributes on model instances', ->
      Person = model.Person
      person = new Person()
      person.set('fullName', "John Doe")
      assert.isDefined(person.attributes.hasFullName)
      assert.isUndefined(person.attributes.fullName)

    it 'should get attributes on model instances', ->
      Person = model.Person
      person = new Person()
      person.set('fullName', "John Doe")
      assert.equal(person.get('fullName'), "John Doe")
      assert.isDefined(person.attributes.hasFullName)
      assert.isUndefined(person.attributes.fullName)

    it 'should set attributes on model instances by inheritance', ->
      c = new model.Country()
      c.set('areaName', "Area 51")
      c.set('squareMeter', 200)
      assert.equal(c.get('areaName'), "Area 51")
      assert.equal(c.get('squareMeter'), 200)

    it 'should set relations on model instances by inheritance', ->
      c1 = new model.Country()
      c2 = new model.Country()
      c1.relation("intersection").add(c2)

      assert.equal(c1.relation("intersection").first().id(), c2.id())

    it 'should add allowed relations by correct range', ->
      Person   = model.Person
      Building = model.Building
      person = new Person()
      person.relation("hasFriend").add(new Person())
      person.relation("livesIn").add(new Building())


    it 'should deny allowed relations by different range', ->
      Person   = model.Person
      Building = model.Building
      person = new Person()
      assert.throws((-> person.relation("livesIn").add(new Weaver.Node())))
      assert.throws((-> person.relation("livesIn").add(new Person())))


    it 'should deny setting invalid model attributes', ->
      Person = model.Person
      person = new Person()
      assert.throws((-> person.set('hasFullName', "John Doe")))


    it 'should deny getting direct instance attributes', ->
      Person = model.Person
      person = new Person()
      person.set('fullName', "John Doe")
      assert.throws((-> person.get('hasFullName')))


    it 'should bootstrap a model', ->
      model.bootstrap().then(->
        new Weaver.Query().restrict('test-model:Person').find()
      ).should.eventually.have.length.be(1)


    it 'should fail saving with type definition that is not yet bootstrapped', ->
      Person = model.Person
      person = new Person()
      person.set("fullName", "Valan son of Glassan")
      assert.throws(person.save)


    describe 'that is bootstrapped', ->
      before ->
        model.bootstrap()


      it 'should not do anything on multiple bootstraps', ->
        model.bootstrap().then(->
          new Weaver.Query().restrict('test-model:Person').find()
        ).should.eventually.have.length.be(1)


      it 'should succeed saving with type definition that is bootstrapped', ->
        Person = model.Person
        person = new Person()
        person.set("fullName", "Arild Askholmen")
        person.save().catch((error) ->
          assert.fail()
        )

      it 'should throw an error when saving without setting required attributes', ->
        Person = model.Person
        person = new Person()
        assert.throws(person.save)

      it 'should throw an error when saving without setting required attributes', ->
        Person = model.Person
        person = new Person()
        assert.throws(person.save)

      it 'should throw an error when saving with min relations required', ->
        b = new model.Building()
        assert.throws(b.save)
        p = new model.Person()
        p.set("fullName", "Hola")
        b.relation("buildBy").add(p)
        b.save()

      it 'should throw an error when saving with max relations required', ->
        b = new model.Building()
        p1 = new model.Person()
        p1.set("fullName", "Hola 1")
        p2 = new model.Person()
        p2.set("fullName", "Hola 2")
        p3 = new model.Person()
        p3.set("fullName", "Hola 3")

        b.relation("buildBy").add(p1)
        b.relation("buildBy").add(p2)
        b.relation("buildBy").add(p3)
        assert.throws(b.save)

      it 'should allow saving at max relations required', ->
        b = new model.Building()
        p1 = new model.Person()
        p1.set("fullName", "Hola 1")
        p2 = new model.Person()
        p2.set("fullName", "Hola 2")

        b.relation("buildBy").add(p1)
        b.relation("buildBy").add(p2)
        b.save()
