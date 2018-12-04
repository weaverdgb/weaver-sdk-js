weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')
cuid   = require('cuid')
moment = require('moment')

describe 'Weaver wpath test', ->

  describe 'wpath with nodes', ->
    n = undefined
    m = undefined
    o = undefined
    p = undefined

    before ->
      o = new Weaver.Node('o')
      p = new Weaver.Node('p')
      m = new Weaver.Node('m')
      m.relation('some').add(o)
      m.relation('some').add(p)
      n = new Weaver.Node('n')
      n.relation('has').add(m)

    it 'should parse a simple expression', ->
      expect(n.wpath(undefined)).to.be.empty
      expect(n.wpath('')).to.be.empty
      assert.deepEqual(n.wpath('/has/some?b'), [{'b':o},{'b':p}])
      assert.deepEqual(n.wpath('has?a'), [{'a':m}])
      assert.deepEqual(n.wpath('/has?a/some?what'), [{'a':m, 'what':o}, {'a':m, 'what':p}])

    it 'should parse an expression with filters', ->
      assert.deepEqual(n.wpath('/has?a/some[id=o|id=p]?b'), [{'a':m, 'b':o}, {'a':m, 'b':p}])
      assert.deepEqual(n.wpath('/has?a/some[id=o]?b'), [{'a':m, 'b':o}])
      assert.deepEqual(n.wpath('/has?a/some[id=p]?b'), [{'a':m, 'b':p}])
      expect(n.wpath('/has?a/some[id=o&id=p]?b')).to.be.empty

    it 'should apply functions', ->
      n.wpath('/has?a/some?b', (row)->row['a'].relation('yes').add(row['b']))
      assert.deepEqual(m.relation('yes').all(), [o, p])

  describe 'wpath with models', ->
    model = {}
    n = undefined
    m = undefined
    o = undefined
    p = undefined

    before ->
      Weaver.Model.load("animal-model", "1.0.0").then((m) ->
        model = m
        model.bootstrap()
      ).then(->
        o = new Weaver.Node('o')
        p = new model.Animal('p')
        m = new Weaver.Node('m')
        m.relation('some').add(o)
        m.relation('some').add(p)  
        n = new Weaver.Node('n')
        n.relation('has').add(m)
      )

    it 'should parse class filter', ->
      assert.deepEqual(n.wpath('/has?a/some[class=animal-model:Animal]?b'), [{'a':m, 'b':p}])

    it 'should ignore non-allowed relation keys', ->
      assert.deepEqual(p.wpath('/has?a/some?b'), [])
