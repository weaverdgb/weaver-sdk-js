require("./test-suite")

describe 'WeaverProject Test', ->

  it 'should create projects with given id', (done) ->
    project = new Weaver.Project("name", "test")
    project.create().then((p) =>
      expect(p.id()).to.equal("test")
      project.destroy()
      done()
    )
    return


  it 'should create projects with no given id', (done) ->
    project = new Weaver.Project()
    project.create().then((p) =>
      expect(p.id()).to.equal(project.id())
      project.destroy()
      done()
    )
    return


  it 'should create projects with attributes', (done) ->
    done()
    return # TODO: Implement this

    project = new Weaver.Project()
    project.set("name", "test")
    project.create().then((p) ->
      expect(p.get("name")).to.equal("test")
      Weaver.Project.load(project.id())
    ).then((loadedProject) ->
      expect(loadedProject.get("name")).to.equal("test")
      project.destroy()
      done()
    )
    return


  it 'should delete projects', (done) ->
    done()
    return # TODO: Project loading does not work, implement this

    test = new Weaver.Project()
    test.create().then((project) ->
      project.destroy().catch((e) ->
        assert(false)
      )
    ).then(->
      Weaver.Project.load(test.id())
    ).catch((error) ->
      console.log(error)
      assert.equal(error.code, Weaver.Error.NODE_NOT_FOUND)
      done()
    )
    return


  # Note that this assumes the projectPool has at least room for two projects
  # TODO: Have a test configuration for Weaver Server with multiple projectPools
  it 'should list projects', (done) ->
    a = new Weaver.Project("A", "a")

    a.create().then(->
      Weaver.Project.list()
    ).then((list) ->
      expect(list.length).to.equal(2)

      loadedA = p for p in list when p.id is 'a'

      expect(loadedA.name).to.equal('A')

    ).then(->
      done()
    ).finally( ->
      Promise.all([a.destroy()])
    )
    return


  it 'should allow setting an active project', (done) ->
    test = new Weaver.Project()
    test.create().then(->
      Weaver.useProject(test)
    ).then( ->
      test.destroy()
    ).then(->
      done()
    )
    return


  it 'should support getting the active project', (done) ->
    test = new Weaver.Project()
    test.create().then((prj) ->
      Weaver.useProject(prj)
      p = Weaver.currentProject()
      expect(p).to.equal(test)
    ).then( ->
      test.destroy()
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
