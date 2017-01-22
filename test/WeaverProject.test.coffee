require("./test-suite")

describe 'WeaverProject Test', ->

  it 'should create projects with given id', (done) ->
    project = new Weaver.Project("test")
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


  it 'should list projects', (done) ->
    a = new Weaver.Project("a")
    b = new Weaver.Project("b")

    a.set('name', 'A')
    a.create().then(->
      b.create()
    ).then(->
      Weaver.Project.list()
    ).then((list) ->
      expect(list.length).to.equal(3)

      loadedA = p for p in list when p.id() is 'a'
      loadedB = p for p in list when p.id() is 'b'

      expect(loadedA.get("name")).to.equal('A')
      expect(loadedB.get("name")).to.be.undefined

      Promise.all([a.destroy(), b.destroy()])
    ).then(->
      done()
    ).catch((Err) -> console.log Err)
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
