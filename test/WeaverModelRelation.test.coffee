weaver  = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver  = require('../src/Weaver')
Promise = require('bluebird')


describe 'Weaver Model relation test', ->
  model = {}

  before ->
    Weaver.Model.load("test-model", "1.2.0").then((m) ->
      model = m
      model.bootstrap()
    ).then(->

      johnny = new model.Person('johnny')
      tim = new model.Person('tim')

      johnny.set('fullName','Johnny Carson')
      tim.set('fullName','Timothy Cooper')

      johnny.relation('hasFriend').add(tim)
      johnny.save()
    )

  it 'should allow Weaver.ModelRelation.prototype.load with an allowed constructor', ->
    j = {}

    model.Person.load('johnny')
    .then((_j)->
      j = _j
      j.relation('hasFriend').load(model.Person)
    ).then(->
      expect(j.relation('hasFriend').first()).to.be.instanceOf(model.Person)
    )

  it 'should throw an error when trying Weaver.ModelRelation.prototype.load with a disallowed constructor', ->

    model.Person.load('johnny').then((j)->
      expect(-> j.relation('hasFriend').load(model.Passport)).to.throw()
    )
