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
