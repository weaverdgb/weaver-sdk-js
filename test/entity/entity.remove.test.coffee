$ = require("./../test-suite")()
sinon   = require("sinon")
Promise = require("bluebird")
Entity = require('../../src/entity')
Weaver = require('../../src/weaver')

describe 'Entity: Removing, unlinking and destroying', ->

  weaver   = new Weaver()
  weaver.connect('http://localhost:9487')

  beforeEach ->
    weaver.repository.clear()


  it 'should correctly remove a key', ->

    entity = weaver.add({name: 'Mo', age: 28})

    entity.should.have.property.name
    entity.should.have.property.age

    weaver.repository.clear()
    # See if stored in server
    weaver.get(entity.$id()).then((serverEntity) ->
      serverEntity.should.have.property.name
      serverEntity.should.have.property.age

      # Remove age
      serverEntity.$remove('age')

      serverEntity.should.not.have.property.age

      # Check server
      weaver.repository.clear()
      weaver.get(entity.$id()).then((secondServerEntity) ->
        secondServerEntity.should.not.have.property.age
      )
    )

  it 'should correctly remove a link', ->

    entity = weaver.add({name: 'Mo', age: 28})
    entity.friend = weaver.add({name: 'Bas'})
    entity.$push('friend')

    entity.should.have.property.friend

    weaver.repository.clear()
    # See if stored in server
    weaver.get(entity.$id(), {eagerness: -1}).then((serverEntity) ->
      serverEntity.should.have.property.friend

      # Remove age
      serverEntity.$remove('friend')

      serverEntity.should.not.have.property.friend

      # Check server
      weaver.repository.clear()
      weaver.get(entity.$id(), {eagerness: -1}).then((secondServerEntity) ->
        secondServerEntity.should.not.have.property.friend
      )
    )

  it 'should correctly destroy an entity', ->

    entity = weaver.add({name: 'Mo', age: 28})
    entity.$destroy()

    weaver.repository.clear()
    # See if stored in server
    weaver.get(entity.$id(), {eagerness: -1}).then((serverEntity) ->
      serverEntity.should.not.have.property.name
      serverEntity.should.not.have.property.age
    )