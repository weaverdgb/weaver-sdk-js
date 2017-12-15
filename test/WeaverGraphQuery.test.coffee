weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'WeaverGraphQuery', ->
  node1 = new Weaver.Node('node1', 'WeaverGraphQuery')
  node2 = new Weaver.Node('node2', 'WeaverGraphQuery')
  node1.relation('test').add(node2)

  before ->
    Weaver.Node.batchSave([node1, node2])

  it 'should allow hasNoRelationOut', ->
    new Weaver.Query()
      .restrictGraphs('WeaverGraphQuery')
      .hasNoRelationOut('test', node2)
      .find().then((nodes) -> (i.id() for i in nodes))
      .should.eventually.eql([ 'node2' ])

  it 'should allow hasRelationOut', ->
    new Weaver.Query()
      .hasRelationOut('test', node2)
      .first()
      .should.eventually.have.property('nodeId').be.equal('node1')

  it 'should allow hasNoRelationIn', ->
    new Weaver.Query()
      .restrictGraphs('WeaverGraphQuery')
      .hasNoRelationIn('test', node1)
      .first()
      .should.eventually.have.property('nodeId').be.equal('node1')

  it 'should allow hasRelationIn', ->
    new Weaver.Query()
      .hasRelationIn('test', node1)
      .first()
      .should.eventually.have.property('nodeId').be.equal('node2')

