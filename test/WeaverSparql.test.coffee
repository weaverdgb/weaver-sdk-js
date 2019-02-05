weaver = require('./test-suite').weaver
wipeCurrentProject = require('./test-suite').wipeCurrentProject
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverSparql Test', ->

  describe 'a simple test set', ->
    x = new Weaver.Node('x')
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')
    d = new Weaver.Node('d')
    a.relation('to').add(x)
    b.relation('to').add(x)
    c.relation('to').add(x)
    d.relation('to').add(x)

    before ->
      wipeCurrentProject().then( ->
        Promise.all([a.save(), b.save(), c.save(), d.save()])
      ).then( ->
        a.destroy()
      ).then( ->
        c.relation('to').remove(x)
      )

    it 'should for partly deleted nodes do a simple Sparql query', ->
      new Weaver.Sparql('SELECT * WHERE { _ ?x to ?y }')
      .find()
      .then((res) ->
        assert.equal(2, res.x.length)
      
        new Weaver.Query()
        .restrict(res.x)
        .find()
      ).then((res) ->
        map = {}
        map[node.id()] = node.relation('to').first().id() for node in res
        assert.deepEqual({ b: 'x', d: 'x' }, map)
      )

  describe 'a cycle of a certain size', ->
    certainSize = 7
    aleph = new Weaver.Node('א‬')
    cycle = (new Weaver.Node("#{i}") for i in [0...certainSize])
    cycle[i].relation('next').add(cycle[(i+1)%cycle.length]) for i in [0...certainSize]
    cycle[i].relation('previous').add(cycle[(cycle.length+i-1)%cycle.length]) for i in [0...certainSize]

    before ->
      wipeCurrentProject().then( ->
        Promise.all([aleph.save(), cycle[0].save()])
      )

    it 'should do a simple Sparql query on a cycle', ->
      new Weaver.Sparql('SELECT * WHERE { _ ?x next _ }')
      .find().then((res) ->
        new Weaver.Query()
        .restrict(res.x)
        .find()
      ).then((res) ->
        assert.equal(cycle.length, res.length)
        for node in res
          number = parseInt(node.id())
          next = parseInt(node.relation('next').first().id())
          previous = parseInt(node.relation('previous').first().id())
          assert.equal((number+1)%cycle.length, next)
          assert.equal((cycle.length+number-1)%cycle.length, previous)
      )

    it 'should find one node from a cycle', ->
      new Weaver.Sparql('SELECT * WHERE { _ ?x next 4 }')
      .find().then((res) ->
        new Weaver.Query()
        .restrict(res.x)
        .find()
      ).then((res) ->
        assert.equal(1, res.length)
        for node in res
          number = parseInt(node.id())
          next = parseInt(node.relation('next').first().id())
          previous = parseInt(node.relation('previous').first().id())
          assert.equal(4, next)
          assert.equal(3, number)
          assert.equal(2, previous)
      )

    it 'should get the nodes using an implicit transaction', ->
      query = new Weaver.Sparql('SELECT * WHERE { _ ?x next ?y }')
      .batchSize(2)
      .keepOpen()

      query.find()
      .then((res) ->
        expect(res.x.length).to.equal(2)
        query.next()
      ).then((res) ->
        expect(res.x.length).to.equal(2)
        query.next()
      ).then((res) ->
        expect(res.x.length).to.equal(2)
        query.next()
      ).then((res) ->
        expect(res.x.length).to.equal(1)
        query.next()
      ).then((res) ->
        expect(res.x.length).to.equal(0)
        query.close()
      ).then( ->
        expect(->query.next()).to.throw('Not able to retrieve next results from a query without open transaction')
      )

    it 'should get the nodes using an explicit transaction', ->
      query = null
      transaction = null
      Weaver.getInstance().startTransaction()
      .then((trx)->
        transaction = trx
        query = new Weaver.Sparql('SELECT * WHERE { _ ?x next ?y }')
        .batchSize(2)
        .keepOpen()
        query.find()
      ).then((res) ->
        expect(res.x.length).to.equal(2)
        query.next()
      ).then((res) ->
        expect(res.x.length).to.equal(2)
        query.next()
      ).then((res) ->
        expect(res.x.length).to.equal(2)
        query.next()
      ).then((res) ->
        expect(res.x.length).to.equal(1)
        query.next()
      ).then((res) ->
        expect(res.x.length).to.equal(0)
        transaction.commit()
      ).then( ->
        expect(->query.next()).to.throw('Not able to retrieve next results from a query without open transaction')
      )

  describe 'a cycle of size 2', ->
    certainSize = 2
    aleph = new Weaver.Node('א‬')
    cycle = (new Weaver.Node("#{i}") for i in [0...certainSize])
    cycle[i].relation('next').add(cycle[(i+1)%cycle.length]) for i in [0...certainSize]
    cycle[i].relation('previous').add(cycle[(cycle.length+i-1)%cycle.length]) for i in [0...certainSize]

    before ->
      wipeCurrentProject().then( ->
        Promise.all([aleph.save(), cycle[0].save()])
      )

    it 'should do a simple Sparql query on a cycle', ->
      new Weaver.Sparql('SELECT * WHERE { _ ?x next _ }')
      .find().then((res) ->
        new Weaver.Query()
        .restrict(res.x)
        .find()
      ).then((res) ->
        assert.equal(cycle.length, res.length)
        for node in res
          number = parseInt(node.id())
          next = parseInt(node.relation('next').first().id())
          previous = parseInt(node.relation('previous').first().id())
          assert.equal((number+1)%cycle.length, next)
          assert.equal((cycle.length+number-1)%cycle.length, previous)
      )

    it 'should find one node from a cycle', ->
      new Weaver.Sparql('SELECT * WHERE { _ ?x next 1 }')
      .find().then((res) ->
        new Weaver.Query()
        .restrict(res.x)
        .find()
      ).then((res) ->
        assert.equal(1, res.length)
        for node in res
          number = parseInt(node.id())
          next = parseInt(node.relation('next').first().id())
          previous = parseInt(node.relation('previous').first().id())
          assert.equal(1, next)
          assert.equal(0, number)
          assert.equal(1, previous)
      )
