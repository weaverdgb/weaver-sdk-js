weaver  = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver  = require('../src/node/Weaver')
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

  it.skip 'should list projects that are not neutered', ->
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

  it 'should create projects with another given id', ->
    project = new Weaver.Project("name", "n-3")
    project.create().then((p) =>
      expect(p.id()).to.equal("n-3")
      p.destroy()
    )

  it 'should create projects with no given id', ->
    project = new Weaver.Project()
    project.create().then((p) =>
      expect(p.id()).to.equal(project.id())
      p.destroy()
    )

  it 'should not create a project with an illegal id, no capital allowed', ->
    id = "Idx"
    new Weaver.Project("name", id).create().should.be.rejectedWith("The id #{id} is not valid")

  it 'should not create a project with an illegal id, no _ allowed', ->
    id = "_dx"
    new Weaver.Project("name", id).create().should.be.rejectedWith("The id #{id} is not valid")

  it 'should not create a project with an illegal id, more than 30 characters no allowed', ->
    id = "1234567890-1234567890-1234567890"
    new Weaver.Project("name", id).create().should.be.rejectedWith("The id #{id} is not valid")

  it 'should not create a project with an illegal id, less than 3 characters not allowed', ->
    id = "dx"
    new Weaver.Project("name", id).create().should.be.rejectedWith("The id #{id} is not valid")

  it 'should not create a project with an illegal id, no special character than - is allowed', ->
    id = "d.x"
    new Weaver.Project("name", id).create().should.be.rejectedWith("The id #{id} is not valid")

  it 'should not create a project with an illegal id, no special character than - is allowed', ->
    id = "d$x"
    new Weaver.Project("name", id).create().should.be.rejectedWith("The id #{id} is not valid")


  it 'should not create a project with an illegal id, no special character than - is allowed', ->
    id = "d/x"
    new Weaver.Project("name", id).create().should.be.rejectedWith("The id #{id} is not valid")

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

  it.skip 'should list projects', ->
    a = new Weaver.Project("A", "aaa")
    a.create().then(->
      Weaver.Project.list()
    ).then((list) ->
      expect(list.length).to.equal(2)
      loadedA = p for p in list when p.id() is 'aaa'
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

  it 'should add metadata to a project', ->
    p = weaver.currentProject()
    appMetadata =
      appName: 'FooBarApp'
      appVersion: '0.2.1-fooBar-b'
      desireSDK: '6.0.1-weaver'
    bundleName = 'apps'
    p.addMetadata(bundleName, appMetadata.appName, appMetadata).then(->
      p.getMetadata(bundleName, appMetadata.appName)
    ).then((metadataProject)->
      assert.deepEqual(appMetadata, metadataProject)
    )

  it 'should remove metadata from a project', ->
    p = weaver.currentProject()
    appMetadata =
      appName: 'FooBarApp'
      appVersion: '0.2.1-fooBar-b'
      desireSDK: '6.0.1-weaver'
    bundleName = 'fooApps'
    p.addMetadata(bundleName, appMetadata.appName, appMetadata).then(->
      p.removeMetadata(bundleName, appMetadata.appName)
    ).then(->
      p.getMetadata(bundleName, appMetadata.appName)
    ).should.be.rejectedWith("No metadata on project #{p.name} for bundleKey fooApps or key FooBarApp")
 
  it 'should be able for a user to retrieve metadata without project administration access', ->
    p = weaver.currentProject()
    appMetadata =
      appName: 'FooBarApp'
      appVersion: '0.2.1-fooBar-b'
      desireSDK: '6.0.1-weaver'
    user = new Weaver.User('testuser', 'testpass', 'test@example.com')
    bundleName = 'apps'
    p.addMetadata(bundleName, appMetadata.appName, appMetadata).then(->
      Weaver.ACL.load(p.acl.id)
    ).then((acl)->
      acl.setUserReadAccess(user, true)
      acl.save()
    ).then(->
      user.create()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpass')
    ).then(->
      p.getMetadata(bundleName, appMetadata.appName)
    ).then((metadataProject)->
      assert.deepEqual(appMetadata, metadataProject)
    ).then(->
      weaver.signOut()
    )
    

  it 'should reject where trying to getMetadata for a non existing metadata related with a bundle and key', ->
    p = weaver.currentProject()
    p.getMetadata('fooBundle','barKey')
      .should.be.rejectedWith("No metadata on project #{p.name} for bundleKey fooBundle or key barKey")

  it 'should reject where trying to getMetadata for a non existing metadata related with a bundle', ->
    p = weaver.currentProject()
    p.getMetadata('fooBundle')
      .should.be.rejectedWith("No metadata on project #{p.name} for bundleKey fooBundle")

  it 'should retrieve all keys for a certain bundle', ->
    p = weaver.currentProject()
    model0 = 
      name: 'foo'
      version: 0
    key0 = 'model0'
    model1 =
      nameApp: 'bar'
      versionApp: '1.0.2'
    key1 = 'model1'
    bundleKey = 'models'
    objectToTest = {
      model0
      model1
    } 
    Promise.join(p.addMetadata(bundleKey,key0,model0),p.addMetadata(bundleKey,key1,model1),->
      p.getMetadata(bundleKey, null)
    ).then((metadataFromBundle)->
      expect(objectToTest).to.eql(metadataFromBundle)
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

  it 'should raise an error while saving without currentProject', ->
    p = weaver.currentProject()
    weaver.useProject(null)
    node = new Weaver.Node()
    node.save()
    .finally(->
      weaver.useProject(p)
    ).should.be.rejected


  it 'should export the database content as snapshot regardless of graph', ->
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

  it 'should export the database content as snapshot per graph', ->
    node = new Weaver.Node()
    node.set('name', 'Foo')
    node.set('age', 20, undefined, undefined, 'age-graph')
    other = new Weaver.Node(undefined, 'somewhere')
    other.set('name', 'Bar')
    node.relation('to').addInGraph(other, 'elsewhere')

    node.save().then((node) ->
      node.save()
    ).then(->

      p = weaver.currentProject()
      p.getSnapshotGraph()
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)

      p = weaver.currentProject()
      p.getSnapshotGraph([])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)

      p = weaver.currentProject()
      p.getSnapshotGraph([null])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(2)

      p = weaver.currentProject()
      p.getSnapshotGraph(['somewhere'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(2)

      p = weaver.currentProject()
      p.getSnapshotGraph(['elsewhere'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(1)

      p = weaver.currentProject()
      p.getSnapshotGraph(['age-graph'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(1)

      p = weaver.currentProject()
      p.getSnapshotGraph(['age-graph', null, 'somewhere', 'elsewhere'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)
    )

  it 'should export the database as snapshot per graph with from and to filters', ->
    a = new Weaver.Node()
    b = new Weaver.Node(undefined, 'graph-b')
    c = new Weaver.Node(undefined, 'graph-c')
    a.relation('to').add(a)
    a.relation('to').add(b)
    a.relation('to').add(c)
    b.relation('to').add(a)
    b.relation('to').add(b)
    b.relation('to').add(c)
    c.relation('to').add(a)
    c.relation('to').add(b)
    c.relation('to').add(c)

    Weaver.Node.batchSave([a, b, c])
    .then(->

      p = weaver.currentProject()
      p.getSnapshotGraph(undefined, [null])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)

      p = weaver.currentProject()
      p.getSnapshotGraph(undefined, ['graph-b'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)

      p = weaver.currentProject()
      p.getSnapshotGraph(undefined, ['graph-c'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)

      p = weaver.currentProject()
      p.getSnapshotGraph(undefined, [null, 'graph-b', 'graph-c'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(12)

      p = weaver.currentProject()
      p.getSnapshotGraph(undefined, undefined, [null])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)

      p = weaver.currentProject()
      p.getSnapshotGraph(undefined, undefined, ['graph-b'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)

      p = weaver.currentProject()
      p.getSnapshotGraph(undefined, undefined, ['graph-c'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(6)

      p = weaver.currentProject()
      p.getSnapshotGraph(undefined, undefined, [null, 'graph-b', 'graph-c'])
    ).then((writeOperations)->
      expect(writeOperations.length).to.equal(12)

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

  it 'should clone a newly created project helloworld', ->
    project = new Weaver.Project("helloworld", "helloworld")
    project.create().then(->
      project.clone('helloworld-dupe', 'helloworld_cloned_db_human_readable_name')
    ).then((p) ->
      expect(p.id()).to.equal('helloworld-dupe')
      p.destroy()
    )

  it 'should not clone a newly created project helloworld', ->
    id = "helloworld_dupe"
    project = new Weaver.Project("helloworld", "helloworld")
    project.create().then(->
      project.clone(id, 'helloworld_cloned_db_human_readable_name')
    ).should.be.rejectedWith("The id #{id} is not valid")

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
      p.getSnapshot(false, true, true)
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

  it 'should should support truncategraph (WEAV-304)', ->
    a = new Weaver.Node(undefined, 'todelete')
    b = new Weaver.Node(undefined, 'toremain')

    Weaver.Node.batchSave([a, b]).then(->
      weaver.currentProject().truncateGraph('todelete', new Weaver.Node(undefined, 'meta'))
    ).then(->
      new Weaver.Query().find()
    ).then((res) ->
      expect(res).to.have.length.be(2)
    )

  it 'should truncategraph with relations in in graph (WEAV-304)', ->
    a = new Weaver.Node(undefined, 'todelete')
    b = new Weaver.Node(undefined, 'toremain')
    a.relation('to').addInGraph(b, 'todelete')

    Weaver.Node.batchSave([a, b]).then(->
      weaver.currentProject().truncateGraph('todelete', new Weaver.Node(undefined, 'meta'))
    )

  it 'should not truncategraph with relations in in other graph (WEAV-304)', ->
    a = new Weaver.Node(undefined, 'todelete')
    b = new Weaver.Node(undefined, 'toremain')
    a.relation('to').addInGraph(b, 'relationgraph')

    Weaver.Node.batchSave([a, b]).then(->
      weaver.currentProject().truncateGraph('todelete', new Weaver.Node(undefined, 'meta'))
    ).should.be.rejectedWith(/relationgraph/)
