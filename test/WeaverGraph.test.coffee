weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')
cuid   = require('cuid')

describe 'WeaverGraph support', ->
  a = new Weaver.Node()
  b = new Weaver.Node()
  aInGraph = new Weaver.Node(a.id(), 'WeaverGraph')
  aInOtherGraph = new Weaver.Node(a.id(), 'WeaverGraph2')
  c = new Weaver.Node(cuid(), 'weaverGraph')

  before ->
    Weaver.Node.batchSave([a, b, aInGraph, aInOtherGraph])

  describe 'in WeaverNode.load', ->
    it 'should load a node with an unspecified graph if the node is in the default graph', ->
      Weaver.Node.load(a.id()).should.not.be.rejected

    it 'should not load a node if the graph is not specified', ->
      Weaver.Node.load(c.id()).should.be.rejected

    it 'should not load a node if the wrong graph is specified', ->
      Weaver.Node.load(b.id(), aInGraph.getGraph()).should.be.rejected

    it 'should load nodes in a graph', ->
      Weaver.Node.loadFromGraph(aInGraph.id(), aInGraph.getGraph()).should.not.be.rejected

  describe 'in WeaverNode getFromGraph', ->
    it 'should support graphs', ->
      expect(Weaver.Node.getFromGraph(a.id(), 'WeaverGraph')).to.have.property('graph').equal('WeaverGraph')

  describe 'in WeaverNode firstOrCreateInGraph', ->
    it 'should get a previously created node', ->
      expect(Weaver.Node.firstOrCreateInGraph(a.id(), 'WeaverGraph'))
        .to.eventually.have.property('graph').equal('WeaverGraph')

    it 'should not create a new node when previously present', ->
      Weaver.Node.firstOrCreateInGraph(a.id(), 'WeaverGraph').then(->
        new Weaver.Query()
          .restrict(a.id())
          .find()
        ).should.eventually.have.length.be(3)

  describe 'in WeaverRelation', ->
    it 'should allow to link to a node in a graph', ->
      b.relation('test').add(aInGraph)
      b.save().then(->
        new Weaver.Query()
          .hasRelationIn('test', b)
          .first()
          .should.eventually.have.property('graph')
          .be.equal('WeaverGraph')
      )

    it 'should set its graph in the write operations', ->
      b = new Weaver.Node()
      c = new Weaver.Node()
      rel = b.relation('test')
      rel.addInGraph(c, 'somegraph')
      expect(rel.pendingWrites[0]).to.have.property('graph').be.equal('somegraph')

  describe 'Graph redirection', ->
    source = 'graph-redir-source'
    oldTarget = 'graph-old-target'
    newTarget = 'graph-new-target'
    a = new Weaver.Node(undefined, source)
    b = new Weaver.Node(undefined, oldTarget)
    c = new Weaver.Node(b.id(), newTarget)
    a.relation('rel').add(b)

    before ->
      Weaver.Node.batchSave([ a, c ])

    it 'should do nothing on dryruns', ->
      weaver.currentProject().redirectGraph(source, oldTarget, newTarget, true, false).then(->
        Weaver.Node.loadFromGraph(a.id(), source)
      ).then((node) ->
        expect(node.relation('rel').all()).to.have.length.be(1)
        expect(node.relation('rel').first().getGraph()).to.equal(oldTarget)
      )

    it 'should work for simple cases', ->
      weaver.currentProject().redirectGraph(source, oldTarget, newTarget, false, false).then(->
        Weaver.Node.loadFromGraph(a.id(), source)
      ).then((node) ->
        expect(i.getGraph() for i in node.relation('rel').all()).to.have.members([ oldTarget, newTarget ])
      )





