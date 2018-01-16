weaver = require("./test-suite").weaver
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

  # Test written to solve the following error, currently only produces debug data and doesnt error
  # ~ Role [uid] users requested, but no longer present in the RoleService
  # Written for WEAV-245 to check for role reference loading issues
  it 'ACL should not throw a role from user requested warning when its no longer present in the RoleService', ->
    acl = new Weaver.ACL()
    role1 = new Weaver.Role("R1")
    role2 = new Weaver.Role("R2")
    user = new Weaver.User('user', 'password', 'email')
    acl.setUserReadAccess(user, true)
    acl.setRoleReadAccess(role1, true)
    acl.setRoleReadAccess(role2, true)

    user.create().then(->
      role1.addUser(user)
      role2.addUser(user)
      Promise.map([role1,role2,acl], (r) -> r.save())
    ).then(->
      role1.destroy()
    ).then(->
      Weaver.ACL.load(acl.id())
    ).then((list) ->
      console.log list
    ).then(->
      user.getRoles()
    ).then((roles) ->
      expect(roles.length).to.equal(1)
    )
