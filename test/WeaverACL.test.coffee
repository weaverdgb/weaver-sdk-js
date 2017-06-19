weaver = require("./test-suite")
Weaver = require('../src/Weaver')
Promise = require('bluebird')

describe 'WeaverACL test', ->

  it 'should create a new ACL', ->
    acl = new Weaver.ACL()
    acl.save().then((acl) ->
      Weaver.ACL.load(acl.id())
    ).then((loadedACL) ->
      assert.equal(loadedACL.id(), acl.id())
    ).catch((Err) -> console.log(Err))

  it 'should add more than one user to a ACL', ->
    user1 = new Weaver.User('user1', 'password1', 'email1')
    user2 = new Weaver.User('user2', 'password2', 'email2')
    user3 = new Weaver.User('user3', 'password3', 'email3')

    Promise.map([user1, user2, user3], (u) -> u.create())
    .then(->
      acl = new Weaver.ACL()
      acl.setUserReadAccess(user1, true)
      acl.setUserReadAccess(user2, true)
      acl.setUserWriteAccess(user1, true)
      acl.setUserWriteAccess(user2, true)
      acl.save()
    ).then((acl) ->

      Weaver.ACL.load(acl.id())

    ).then((loadedACL) ->

      loadedACL.setUserReadAccess(user3, true)
      loadedACL.setUserWriteAccess(user3, true)
      loadedACL.save()

    ).then((acl) ->
      Weaver.ACL.load(acl.id())

    ).then((loadedACL) ->
      assert.equal((key for key of loadedACL._userReadMap).length, 3)
      assert.equal((key for key of loadedACL._userWriteMap).length, 3)
    )

  it 'should not be able to delete Server Function ACLs', ->
    Weaver.ACL.load('create-projects').then((acl) ->
      assert.fail()
    ).catch(->
      # This is fine
    )

