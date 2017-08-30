weaver  = require("./test-suite")
Weaver  = require('../src/Weaver')
Promise = require('bluebird')

describe 'WeaverProject Test', ->
  actualProject = (p) ->
    expect(p).to.have.property('_stored').to.be.a('boolean').to.equal(true)
    expect(p).to.have.property('destroy').be.a('function')
    expect(p).to.have.property('acl').to.exist

  it 'should have currentProject be not neutered', ->
    actualProject(weaver.currentProject())

  it 'should list projects that are not neutered', ->
    Weaver.Project.list().then((list) ->
      expect(list).to.have.length.be(1)
      actualProject(list[0])
    )

  it 'should create projects with given id', ->
    project = new Weaver.Project("name", "test")
    project.create().then((p) =>
      expect(p.id()).to.equal("test")
      p.destroy()
    )

  it 'should create projects with no given id', ->
    project = new Weaver.Project()
    project.create().then((p) =>
      expect(p.id()).to.equal(project.id())
      p.destroy()
    )

  it 'should delete projects', ->
    test = new Weaver.Project()
    id = 'deleteid'
    test.create(id).then((project) ->
      project.destroy()
    ).then(->
      Weaver.Project.list()
    ).then((list)->
      filtered = (i for i in list when i.id is id)
      expect(filtered).to.have.length.be(0)
    )

  it 'should list projects', ->
    a = new Weaver.Project("A", "a")
    a.create().then(->
      Weaver.Project.list()
    ).then((list) ->
      expect(list.length).to.equal(2)
      loadedA = p for p in list when p.id() is 'a'
      expect(loadedA).to.be.defined
      expect(loadedA.name).to.equal('A')
    ).then(->
      a.destroy()
    )


  it 'should allow setting an active project', ->
    p = weaver.currentProject()
    test = new Weaver.Project()
    test.create().then(->
      weaver.useProject(test)
    ).then(->
      expect(weaver.currentProject()).to.eql(test)
      test.destroy()
      weaver.useProject(p)
    )

  it 'should freeze a project making writing impossible', ->
    p = weaver.currentProject()
    p.freeze().then(->
      a = new Weaver.Node()
      a.save().then(->
        assert(false, "Writing a node after freeze should not be possible")
      ).catch((err)->
        assert.include(err.message, "Project is frozen")
      )
    ).catch((err)->
      assert(false, "Default case is to fail this test, project wasn't frozen? " + err.message)
    )

  it 'should unfreeze a project making writing possible', ->
    p = weaver.currentProject()
    p.unfreeze().then(->
      a = new Weaver.Node()
      a.save().then(->
        assert(true)
      ).catch((err)->
        assert(false, "Node fails to write, project is frozen? " + err.message)
      )
    ).catch((err)->
      assert(false, "Default case is to fail this test, project is frozen? " + err.message)
    )

  it.skip 'should raise an error while saving without currentProject', (done) ->
    p = weaver.currentProject()
    weaver.useProject(null)
    node = new Weaver.Node()
    node.save().then(->
      assert false
    )
    .catch((error)->
      assert true
    ).finally(->
      weaver.useProject(p)
      done()
    )
    return

  it.skip 'should export the database content as snapshot', ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('name', 'Foo')
      node.save()
    ).then(->
      p = weaver.currentProject()
      p.getSnapshot()
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(2)
    )

  it 'should not leak internal details of projects', ->
    weaver.coreManager.listProjects().then((projects) ->
      p = projects[0]
      expect(p).to.not.have.property('tracker')
      expect(p).to.not.have.property('meta')
      expect(p).to.not.have.property('$loki')
      expect(p).to.not.have.property('database')
      expect(p).to.not.have.property('fileServer')
    )

  it 'should now allow checking project readyness without access', ->
    weaver.signOut().then(->weaver.coreManager.readyProject(weaver.currentProject().projectId)).should.be.rejected

  it 'should allow checking project readyness for admin' , ->
    weaver.coreManager.readyProject(weaver.currentProject().projectId).should.eventually.eql({ready: true})

  it 'should allow checking project readyness for regular users with access' , ->
    testUser = new Weaver.User('testuser', 'testpassword', 'test@example.com')
    Promise.join(
      testUser.create(),
      weaver.currentProject().getACL()
      (user, acl) ->
        acl.setUserReadAccess(testUser, true)
        acl.save()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      weaver.coreManager.readyProject(weaver.currentProject().projectId)
    ).should.eventually.eql({ready: true})


  it 'should not allow unauthorized snapshots', ->
    new Weaver.User('testuser', 'testpass', 'test@example.com').signUp().then(->
      weaver.currentProject().getSnapshot()
    ).should.be.rejectedWith(/Permission denied/)

  it.skip 'should clone a newly created project helloworld', ->
    project = new Weaver.Project("helloworld", "helloworld")
    project.create().then(->
      project.clone('helloworld_dupe', 'helloworld_cloned_db_human_readable_name')
    ).then((p) ->
      expect(p.id()).to.equal('helloworld_dupe')
      p.destroy()
    )
