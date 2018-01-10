weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'WeaverGraph support', ->
  a = new Weaver.Node()
  b = new Weaver.Node()
  aInGraph = new Weaver.Node(a.id(), 'WeaverGraph')
  aInOtherGraph = new Weaver.Node(a.id(), 'WeaverGraph2')
  
  before ->
    Weaver.Node.batchSave([a, b, aInGraph, aInOtherGraph])

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
