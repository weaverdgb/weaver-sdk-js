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
    Weaver.Project.create().then((p) =>
      console.log("Project create")
      console.log(p)
      expect(p.name).to.equal("test")
      expect(p.id).to.not.be.undefined
    )
  
  it 'should list projects not done', ->
    Weaver.Project.list()
    .then((list) ->
      assert(list)
    )

  it 'should delete projects', (done) ->
    Weaver.Project.create('testProject').then((project) ->
      Weaver.Project.delete(project).then( ->
        assert(true)
        done()
      )
    )
    return
