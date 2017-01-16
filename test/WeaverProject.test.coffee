require("./test-suite")()

expect = require('chai').expect

Weaver      = require('./../src/Weaver')
WeaverError = require('./../../weaver-commons-js/src/WeaverError')
require('./../src/WeaverProject')

describe 'Weaver Project', ->
  before (done) ->
    Weaver.initialize(WEAVER_ADDRESS)
    .then(->
      wipe()
    ).then(->
      done()
    )
    return

  it 'should create projects', ->
    project = new Weaver.Project()
    project.name = "test"
    project.create().then((p) =>
      expect(p.name).to.equal("test")
      expect(p.id).to.not.be.undefined
    )
  
  it 'should list projects not done', ->
    Weaver.Project.list()
    .then((list) ->
      expect(list.length).to.exist
      expect(list[0]).to.be.an.instanceof(Weaver.Project) if list.length > 0
    )

  it 'should delete projects', ->
    test = new Weaver.Project()
    test.name = "To be deleted"
    test.create().then((project) ->
      project.delete().then( ->
        assert(true)
      )
    )

  it 'should allow setting an active project', ->
    test = new Weaver.Project()
    test.name = "The project to be used"
    test.create().then((prj) ->
      Weaver.Project.useProject(prj).then( ->
        prj.delete()
      )
    )

  it 'should support getting the active project', ->
    test = new Weaver.Project()
    test.name = "This should be activated"
    test.create().then((prj) ->
      Weaver.Project.useProject(prj).then( ->
        p = Weaver.Project.getActiveProject()
        expect(p.name).to.equal("This should be activated")
      ).then( ->
        prj.delete()
      )
    )
