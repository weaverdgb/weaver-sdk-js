weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverQuery Narql Test', ->

  describe 'clean nodes, without links', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    a.relation('to').add(c)
    b.relation('to').add(c)

    before ->
      wipeCurrentProject().then( ->
        Promise.all([a.save(), b.save()])
      ).then( ->
        a.destroy()
      )

    it 'should do a simple narql query', ->
      new Weaver.Narql('_ ?x to ?y .')
      .find().then((res) ->
        console.log res

        new Weaver.Query()
        .restrict(res.a)
        .find()
      ).then((res) ->
        console.log res
      )
