weaver  = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver  = require('../src/Weaver')
Promise = require('bluebird')
path    = require('path')

describe 'WeaverProject Test', ->
  beforeEach ->
    wipeCurrentProject()

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

  it 'should add a project app, with some metadata', ->
    p = weaver.currentProject()
    appMetadata =
      appName: 'FooBarApp'
      appVersion: '0.2.1-fooBar-b'
      desireSDK: '6.0.1-weaver'
    p.addApp(appMetadata.appName,appMetadata).then(->
      assert.equal(appMetadata, p.getApps()[0])
    )

  it 'should remove a project app', ->
    p = weaver.currentProject()
    appMetadata =
      appName: 'FooBarApp'
      appVersion: '0.2.1-fooBar-b'
      desireSDK: '6.0.1-weaver'
    p.addApp(appMetadata.appName,appMetadata).then(->
      p.removeApp(appMetadata.appName)
    ).then(->
      assert.equal(p.getApps().length, 0)
    )

  it 'should freeze a project making writing impossible', ->
    weaver.currentProject().freeze().then(->
      (new Weaver.Node()).save().should.be.rejected
    )

  it 'should unfreeze a project making writing possible', ->
    weaver.currentProject().unfreeze().then(->
      (new Weaver.Node()).save().should.not.be.rejected
    )

  it 'should retrieve the freeze status of a frozen project, calling isFrozen', ->
    weaver.currentProject().freeze().then(->
      weaver.currentProject().isFrozen()
    ).then((res) ->
      expect(res.status).to.be.true
    )

  it 'should retrieve the freeze status of a non frozen project, calling isFrozen', ->
    weaver.currentProject().unfreeze().then(->
      weaver.currentProject().isFrozen()
    ).then((res) ->
      expect(res.status).to.be.false
    )

  it 'should be unable to freeze project due to acls', ->
    new Weaver.User('testuser', 'testpass', 'test@example.com').signUp().then(->
      weaver.signInWithUsername('testuser', 'testpass')
    ).then(->
      weaver.currentProject().freeze()
    ).should.be.rejectedWith(/Permission denied/)

  it 'should be unable to unfreeze a project due to acls', ->
    weaver.currentProject().freeze().then(->
      new Weaver.User('testuser', 'testpass', 'test@example.com').signUp()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpass')
    ).then( ->
      weaver.currentProject().unfreeze()
    ).should.be.rejectedWith(/Permission denied/)

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

  it 'should export the database content as snapshot', ->
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
    weaver.coreManager.readyProject(weaver.currentProject().projectId).should.eventually.contain({ready: true})

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
    ).should.eventually.contain({ready: true})


  it 'should not allow unauthorized snapshots', ->
    new Weaver.User('testuser', 'testpass', 'test@example.com').signUp().then(->
      weaver.signInWithUsername('testuser', 'testpass')
    ).then(->
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

  it 'should rename a project on the server and local', ->
    p = weaver.currentProject()
    p.rename('rename_test').then(->
      Weaver.Project.list().then((list)->
        expect(list[0].name).to.equal('rename_test')
        expect(p.name).to.equal('rename_test')
      )
    )

  it 'should not be able to rename a project with insufficient permissions', ->
    new Weaver.User('testuser', 'testpass', 'test@example.com').signUp().then(->
      weaver.signInWithUsername('testuser', 'testpass')
    ).then(->
      weaver.currentProject().rename('rename_test')
    ).should.be.rejectedWith(/Permission denied/)

  it 'should snapshot a project and get a minio filename gz', ->
    p = weaver.currentProject()

    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()
    d = new Weaver.Node()

    a.relation('link').add(b)
    c.relation('link').add(d)
    Promise.all([a.save(), b.save(), c.save(), d.save()]).then(->
      p.getSnapshot(true)
    ).then((file)->
      assert.include(file.name, ".gz")
    )

  it 'should upload and execute a zip with writeoperations', ->
    @skip() if window?
    weaverFile = new Weaver.File(path.join(__dirname,'../test-write-operations.gz'))
    weaverFile.upload().then((file)->
      p = weaver.currentProject()
      p.executeZip(file.id())
    ).then(->
      Weaver.Node.load("cj7a73kr000036dp4jbxqq3n4")
    ).then(->
      Weaver.Node.load("cj7a73kr000046dp4lhu1u5eu")
    ).then(->
      Weaver.Node.load("cj7a73kr000056dp4gujh1qcf")
    ).then(->
      Weaver.Node.load("cj7a73kr000066dp45qo9acyz")
    )
