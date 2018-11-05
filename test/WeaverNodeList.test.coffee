weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverNodeList test', ->

  it 'should flatten a NodeList by a relation', ->
    wipeCurrentProject().then(->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      d = new Weaver.Node('d')

      a.relation('rel').add(b)
      b.relation('rel').add(c)
      c.relation('rel').add(d)

      a.save().then(->
        new Weaver.Query()
        .restrict(['a'])
        .selectRecursiveOut('rel')
        .find()
      ).then((res)->
        nodes = res.flattenByRelation('rel')
        .reduceDeepestLoaded()
        assert.equal(nodes.length, 4)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
        checkNodeInResult(nodes, 'd')
      )
    )

  it 'should flatten a NodeList by a relation (and miss relations not included in relsToTraverse)', ->
    wipeCurrentProject().then(->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      d = new Weaver.Node('d')

      a.relation('rel').add(b)
      b.relation('rel').add(c)
      c.relation('rong').add(d)

      a.save().then(->
        new Weaver.Query()
        .restrict(['a'])
        .selectRecursiveOut('rel')
        .find()
      ).then((res)->
        nodes = res.flattenByRelation('rel')
        .reduceDeepestLoaded()
        assert.equal(nodes.length, 3)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )
    )

  it 'should not break on recursive relations', ->
    wipeCurrentProject().then(->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      d = new Weaver.Node('d')

      a.relation('rel').add(b)
      b.relation('rel').add(c)
      c.relation('rel').add(d)

      b.relation('rel').add(a)
      d.relation('rel').add(a)

      a.save().then(->
        new Weaver.Query()
        .restrict(['a'])
        .selectRecursiveOut('rel')
        .find()
      ).then((res)->
        nodes = res.flattenByRelation('rel')
        .reduceDeepestLoaded()
        assert.equal(nodes.length, 4)
      )
    )

  it 'should include nodes which are not _loaded', ->
    wipeCurrentProject().then(->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')

      a.relation('rel').add(b)
      b.relation('rel').add(c)

      a.save().then(->
        new Weaver.Query()
        .hasRelationOut('rel')
        .find()
      ).then((res)->
        nodes = res.flattenByRelation('rel')
        .reduceDeepestLoaded()
        assert.equal(nodes.length, 3)
        checkNodeInResult(nodes, 'c')
        nodes.map((n)->
          if n.id() is 'c'
            assert.equal(n._loaded, false)
        )
      )
    )

  it 'should be able to do reduceOnlyLoaded', ->
    wipeCurrentProject().then(->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')

      a.relation('rel').add(b)
      b.relation('rel').add(c)

      a.save().then(->
        new Weaver.Query()
        .hasRelationOut('rel')
        .find()
      ).then((res)->
        nodes = res.flattenByRelation('rel')
        .reduceDeepestLoaded()
        .reduceOnlyLoaded()
        assert.equal(nodes.length, 2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )
    )
