require("./test-suite")

describe 'WeaverProject Test', ->
  it 'should create projects with given id', (done) ->
    project = new Weaver.Project("name", "test")
    project.create().then((p) =>
      expect(p.id()).to.equal("test")
      p.destroy()
      done()
    )
    return

  it.skip 'should create projects with no given id', (done) ->
    project = new Weaver.Project()
    project.create().then((p) =>
      expect(p.id()).to.equal(project.id())
      p.destroy()
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
      p.destroy()
      done()
    )
    return

  it 'should delete projects', (done) ->
    test = new Weaver.Project()
    id = 'deleteid'
    test.create(id).then((project) ->
      project.destroy().catch((e) ->
        assert(false)
      )
    ).then(->
      Weaver.Project.list()
    ).then((list)->
      filtered = (i for i in list when i.id is id)
      expect(filtered).to.have.length.be(0)
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
      a.destroy()
      done()
    )
    return


  it.skip 'should allow setting an active project', (done) ->
    test = new Weaver.Project()
    test.create().then(->
      Weaver.useProject(test)
    ).then(->
      test.destroy()
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
      test.destroy()
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
