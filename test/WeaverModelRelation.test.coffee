weaver  = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver  = require('../src/Weaver')
Promise = require('bluebird')


describe 'Weaver Model relation test', ->
  model = {}

  before ->
    jill = {}

    Weaver.Model.load("test-model", "1.2.0").then((m) ->
      model = m
      model.bootstrap()
    ).then(->

      johnny = new model.Person('johnny')
      tim = new model.Person('tim')
      jill = new model.Person('jill')

      johnny.set('fullName','Johnny Carson')
      tim.set('fullName','Timothy Cooper')
      jill.set('fullName', 'Jill O\' Quill')

      johnny.relation('hasFriend').add(tim)
      johnny.save()
    ).then(->
      jill.save()
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

  it 'should do Weaver.ModelRelation.prototype.update()', ->
    johnny = {}
    jill = {}
    tim = {}

    model.Person.load('johnny').then((_j)->
      johnny = _j
      model.Person.load('jill')
    ).then((_i)->
      jill = _i
      model.Person.load('tim')
    ).then((_t)->
      tim = _t
      johnny.relation('hasFriend').update(tim, jill)
      expect(johnny.relation('hasFriend').first().get('fullName')).to.equal('Jill O\' Quill')
      johnny.save()
    ).then((j)->
      expect(j.relation('hasFriend').first().get('fullName')).to.equal('Jill O\' Quill')
    )
