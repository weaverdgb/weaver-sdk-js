weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')
cuid   = require('cuid')

describe 'WeaverModelQuery test', ->
  model = {}

  before ->
    Weaver.Model.load("test-model", "1.0.0").then((m) ->
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
      assert.equal(instances.length, 1)
      assert.equal(instances[0].constructor, model.Person)
      assert.equal(instances[0].get('fullName'), 'John Doe')
    )


  it.skip 'should do Weaver.Query from the default currentModel', ->
    Weaver.useModel(model)
    assert.equal(model, Weaver.currentModel())

    new Weaver.ModelQuery()
    .class(model.Person)
    .count()
