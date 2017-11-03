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


    describe 'that is bootstrapped', ->
      before ->
        model.bootstrap()

      it 'should not do anything on multiple bootstraps', ->
        model.bootstrap().then(->
          new Weaver.Query().restrict('test-model:Person').find()
        ).should.eventually.have.length.be(1)

      it.skip 'should do Weaver.Query on models', ->
        new Weaver.Query()
          .model(model.Person)
          .contains("fullName", "John")
          .first()
          .then((person) ->
            assert.equal(person.get("fullName", "John Doe"))
            # also assert person is of class Person
          )
