weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'WeaverGraph support', ->
  a = new Weaver.Node()
  aInGraph = new Weaver.Node(a.id(), 'WeaverGraph')
  aInOtherGraph = new Weaver.Node(a.id(), 'WeaverGraph2')
  
  before ->
    Weaver.Node.batchSave([a, aInGraph, aInOtherGraph])

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

