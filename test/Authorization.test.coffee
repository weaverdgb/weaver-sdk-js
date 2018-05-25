weaver             = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
signInAsAdmin      = require("./test-suite").signInAsAdmin

Weaver = require('../src/Weaver')
Promise = require('bluebird')

cuid = require('cuid')

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
    Promise.join(testUser.create(), Weaver.ACL.load('project-administration'), (user, acl) ->
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
    )

  it 'should allow a user to destroy a project created by that user', ->
    testProject = weaver.currentProject()
    testUser = new Weaver.User(cuid(), 'testpassword', "#{cuid()}@dontevenvalidate.com")
    Promise.join(testUser.create(), Weaver.ACL.load('project-administration'), (user, acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername(testUser.username, 'testpassword')
    ).then(->
      p = new Weaver.Project('A created project')
      weaver.useProject(p)
      p.create()
    ).then((project) ->
      project.destroy()
    ).finally( ->
      signInAsAdmin().then(->
        weaver.useProject(testProject)
      )
    )

  it 'should not allow a user to delete a project by default', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    testUser2 = new Weaver.User('another', 'testpassword', 'email@email.com')
    Promise.join(weaver.currentProject().destroy(), testUser.create(), testUser2.create(), Weaver.ACL.load('project-administration'), (deleteResult, user, user2, acl) ->
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

  it 'should not allow a user to delete a project if it is an admin even though he may not have read access', ->
    testProject = weaver.currentProject()
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    testUser2 = new Weaver.User('another', 'testpassword', 'email@email.com')
    Promise.join(weaver.currentProject().destroy(), testUser.create(), testUser2.create(), Weaver.ACL.load('project-administration'), (deleteResult, user, user2, acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.setUserWriteAccess(testUser2, true)
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
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('another', 'testpassword')
    ).then(->
      weaver.currentProject().destroy()
    ).finally(->
      signInAsAdmin().then(->
        weaver.useProject(testProject)
      )
    )

  it 'should allow a user to write to projects he created', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    Promise.join(weaver.currentProject().destroy(), testUser.create(), Weaver.ACL.load('project-administration'), (deleteResult, user, acl) ->
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
      Weaver.ACL.load('project-administration')
    ).then((acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.save()
    ).should.be.rejected

  it 'should prevent system acls from being deleted', ->
    Weaver.ACL.load('project-administration').then((acl) ->
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



