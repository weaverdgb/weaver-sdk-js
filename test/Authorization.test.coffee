weaver = require("./test-suite")
Weaver = require('../src/Weaver')
Promise = require('bluebird')

describe 'Authorization test', ->
  beforeEach ->
    wipeCurrentProject()


  it 'should not allow project creation by default', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    testUser.create().then((user) ->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      p = new Weaver.Project('doesnt matter', 'this-should-fail')
      p.create()
    ).then(->
      assert.fail()
    ).catch((err)->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should allow project creation when authorized', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    Promise.join(testUser.create(), Weaver.ACL.load('create-projects'), (user, acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      p = new Weaver.Project('A created project')
      p.create()
    ).then((project) ->
      project.destroy()
    ).catch((err) ->
      # workaround for the limited developemt projects
      expect(err).to.have.property('message').match(/No more available projects/)
    )

  it 'should allow a user to destroy a project created by that user', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    Promise.join(weaver.currentProject().destroy(), testUser.create(), Weaver.ACL.load('create-projects'), (deleteResult, user, acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      p = new Weaver.Project('A created project')
      weaver.useProject(p)
      p.create()
    ).then((project) ->
      project.destroy()
    ).then(->
      p = new Weaver.Project("yet another project", 'test')
      weaver.useProject(p)
      p.create()
    )

  it 'should not allow a user to delete a project by default', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    testUser2 = new Weaver.User('another', 'testpassword', 'email@email.com')
    Promise.join(weaver.currentProject().destroy(), testUser.create(), testUser2.create(), Weaver.ACL.load('create-projects'), (deleteResult, user, user2, acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      p = new Weaver.Project('A created project')
      weaver.useProject(p)
      p.create()
    ).then(->
      weaver.currentProject().getACL()
    ).then((acl) ->
      acl.setUserWriteAccess(testUser2, true)
      acl.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('another', 'testpassword')
    ).then(->
      weaver.currentProject().destroy()
    ).should.be.rejected

  it 'should allow a user to write to projects he created', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    Promise.join(weaver.currentProject().destroy(), testUser.create(), Weaver.ACL.load('create-projects'), (deleteResult, user, acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      p = new Weaver.Project('A created project')
      weaver.useProject(p)
      p.create()
    ).then(->
      node = new Weaver.Node()
      node.save()
    )

  it 'should prevent unauthorized permission modification', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    testUser.create().then((user) ->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      Weaver.ACL.load('create-projects')
    ).then((acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.save()
    ).should.be.rejected

  it 'should prevent system acls from being deleted', ->
    Weaver.ACL.load('create-projects').then((acl) ->
      acl.delete()
    ).should.be.rejected

  it 'should hide projects a user has no access to', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    testUser.create().then((user) ->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      Weaver.Project.list()
    ).should.eventually.have.length.be(0)

  it 'should be able to give access to projects', ->
    weaver.currentProject().destroy().then(->
      project = new Weaver.Project('another-test')
      project.create()
    ).then((project) ->
      weaver.useProject(project)
      testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
      Promise.join(testUser.create(), weaver.currentProject().getACL(), (user, acl) ->
        acl.setUserReadAccess(testUser, true)
        acl.save()
      )
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      Weaver.Project.list()
    ).should.eventually.have.length.be(1)



