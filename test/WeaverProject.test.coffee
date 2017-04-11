require("./test-suite")

describe 'WeaverProject Test', ->

  it.skip 'should create projects with given id', (done) ->
    project = new Weaver.Project("name", "test")
    project.create().then((p) =>
      expect(p.id()).to.equal("test")
      done()
    )
    return


  it.skip 'should create projects with no given id', (done) ->
    project = new Weaver.Project()
    project.create().then((p) =>
      expect(p.id()).to.equal(project.id())
      done()
    )
    return


  it.skip 'should create projects with attributes', (done) ->
    project = new Weaver.Project()
    project.set("name", "test")
    project.create().then((p) ->
      expect(p.get("name")).to.equal("test")
      Weaver.Project.load(project.id())
    ).then((loadedProject) ->
      expect(loadedProject.get("name")).to.equal("test")
      done()
    )
    return


  it.skip 'should delete projects', (done) ->
    test = new Weaver.Project()
    test.create().then((project) ->
      project.destroy().catch((e) ->
        assert(false)
      )
    ).then(->
      Weaver.Project.load(test.id())
    ).catch((error) ->
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
      done()
    )
    return


  # Note that this assumes the projectPool has at least room for two projects
  # TODO: Have a test configuration for Weaver Server with multiple projectPools
  it.skip 'should list projects', (done) ->
    a = new Weaver.Project("A", "a")

    a.create().then(->
      Weaver.Project.list()
    ).then((list) ->
      expect(list.length).to.equal(2)

      loadedA = p for p in list when p.id is 'a'

      expect(loadedA.name).to.equal('A')

    ).then(->
      done()
    )
    return


  it.skip 'should allow setting an active project', (done) ->
    test = new Weaver.Project()
    test.create().then(->
      Weaver.useProject(test)
    ).then(->
      done()
    )
    return


  it.skip 'should support getting the active project', (done) ->
    test = new Weaver.Project()
    test.create().then((prj) ->
      Weaver.useProject(prj)
      p = Weaver.currentProject()
      expect(p).to.equal(test)
    ).then(->
      done()
    )
    return


  it 'should raise an error while saving without currentProject', (done) ->
    Weaver.useProject(null)
    node = new Weaver.Node()
    node.save().catch((error)->
      assert.equal(error.code, -1)
      done()
    )
    return
