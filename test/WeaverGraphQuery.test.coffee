weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'WeaverGraphQuery', ->
  node1a = new Weaver.Node('node1')
  node1 = new Weaver.Node('node1', 'WeaverGraphQuery')
  node2a = new Weaver.Node('node2')
  node2 = new Weaver.Node('node2', 'WeaverGraphQuery')
  node3a = new Weaver.Node('node3')
  node3 = new Weaver.Node('node3', 'WeaverGraphQuery')
  node1.relation('test').add(node2)
  node2.relation('test').add(node3)
  node1a.relation('test').add(node2a)
  node2a.relation('test').add(node3a)

  before ->
    Weaver.Node.batchSave([node1, node1a])

  it 'should allow hasNoRelationOut', ->
    new Weaver.Query()
      .restrictGraphs('WeaverGraphQuery')
      .hasNoRelationOut('test', node2)
      .find().then((nodes) -> (i.id() for i in nodes))
      .should.eventually.eql([ 'node2', 'node3' ])

  it 'should allow hasRelationOut', ->
    new Weaver.Query()
      .hasRelationOut('test', node2)
      .first()
      .should.eventually.have.property('nodeId').be.equal('node1')

  it 'should allow recursive hasRelationOut', ->
    new Weaver.Query()
      .hasRecursiveRelationOut('test', node3, true)
      .find().then((nodes) -> (i.id() for i in nodes))
      .should.eventually.eql([ 'node1', 'node2', 'node3' ])

  it 'should allow hasNoRelationIn', ->
    new Weaver.Query()
      .restrictGraphs('WeaverGraphQuery')
      .hasNoRelationIn('test', node1)
      .find().then((nodes) -> (i.id() for i in nodes))
      .should.eventually.eql([ 'node1', 'node3' ])

  it 'should allow hasRelationIn', ->
    new Weaver.Query()
      .hasRelationIn('test', node1)
      .first()
      .should.eventually.have.property('nodeId').be.equal('node2')

  it 'should allow recursive hasRelationIn', ->
    new Weaver.Query()
      .hasRecursiveRelationIn('test', node1)
      .find().then((nodes) -> (i.id() for i in nodes))
      .should.eventually.eql([ 'node2', 'node3' ])
