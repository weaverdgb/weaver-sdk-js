weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'Weaver relation and WeaverRelationNode test', ->
  it 'should add a new relation without id', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    rel = null
    loadedRel = null

    assert(!foo._loaded)
    assert(!foo._stored)
    assert(!bar._loaded)
    assert(!bar._stored)

    foo.relation('comesBefore').add(bar)
    foo.save().then(->
      assert(!foo._loaded)
      assert(foo._stored)
      assert(!bar._loaded)
      assert(bar._stored)

      foo.relation('comesBefore').to(bar)
    ).then((relation)->
      rel = relation
      assert.isTrue(rel instanceof Weaver.RelationNode)
      assert.isDefined(rel)
      assert.isDefined(rel.id())

      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      assert.isDefined(loadedNode.relation('comesBefore').all().find((x) -> x.equals(bar)))

      assert(loadedNode._loaded)
      assert(loadedNode._stored)
      expect(loadedNode.relation('comesBefore').all().find((x) -> x.equals(bar))).to.have.property('_loaded').equal(false)
      assert(loadedNode.relation('comesBefore').all().find((x) -> x.equals(bar))._stored)

      loadedNode.relation('comesBefore').to(bar)
    ).then((relation) ->
      loadedRel = relation
      assert.isTrue(loadedRel instanceof Weaver.RelationNode)
      assert.equal(loadedRel.id(), rel.id())
    )

  it 'should add a new relation with id', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    rel = foo.relation('comesBefore').add(bar, 'abc')
    expect(rel).to.be.instanceOf(Weaver.RelationNode)
    foo.save().then(->
      Weaver.Node.load('abc', undefined, undefined, true)
    ).then((loadedNode) ->
      assert.isDefined(loadedNode)
    )

  it 'should load the to nodes of a relation', ->
    loadedNode = null
    foo = new Weaver.Node('foo')
    bar = new Weaver.Node('bar')
    kik = new Weaver.Node('kik')
    foo.relation('link').add(bar)
    bar.relation('link').add(kik)
    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((node)->
      loadedNode = node
      loadedNode.relation('link').load(Weaver.Node)
    ).then(->
      expect(loadedNode.relation('link').first().relation('link').first()).to.be.instanceOf(Weaver.Node)
    )

  it 'should save a new relation on relation on node save', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    bass = new Weaver.Node()
    rel = foo.relation('comesBefore').add(bar)
    expect(rel).to.be.instanceOf(Weaver.RelationNode)
    rel.relation('item').add(bass)
    foo.save().then(->
      Weaver.Node.load(rel.id(), undefined, undefined, true)
    ).then((loadedRelNode) ->
      assert.isDefined(loadedRelNode)
      expect(loadedRelNode.relation('item').all()).to.have.length.be(1)
    )

  it 'should update a relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    ono = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    Weaver.Node.batchSave([foo, bar, ono]).then(->
      foo.relation('comesBefore').update(bar, ono)
      foo.save()
    ).then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      expect(loadedNode.relation('comesBefore').all().find((x) -> x.equals(ono))).to.be.defined
      expect(loadedNode.relation('comesBefore').all().find((x) -> x.equals(bar))).to.not.be.defined
    )

  it 'should remove a relation from the loaded result', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    zoo = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').add(zoo)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      expect(i.id() for i in loadedNode.relation('comesBefore').all()).to.have.length.be(2)
      loadedNode.relation('comesBefore').remove(loadedNode.relation('comesBefore').first())
    ).then( ->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      expect(i.id() for i in loadedNode.relation('comesBefore').all()).to.have.length.be(1)
    )

  it 'should remove a relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    zoo = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').add(zoo)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      loadedNode.relation('comesBefore').remove(bar)
    ).then( ->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      expect(i.id() for i in loadedNode.relation('comesBefore').all()).to.have.length.be(1)
    )

  it 'should remove all in relation', ->
    loadedNode = undefined
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').add(bar)
    expect(foo.relation('comesBefore').all()).to.have.length.be(2)
    expect(foo.relation('comesBefore').allRecords()).to.have.length.be(2)
    expect(foo.relation('comesBefore').all()).to.have.length.be(2)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((n) ->
      loadedNode = n
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(2)
      expect(loadedNode.relation('comesBefore').allRecords()).to.have.length.be(2)
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(2)

      loadedNode.relation('comesBefore').remove(bar)
    ).then( ->
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(0)
      expect(loadedNode.relation('comesBefore').allRecords()).to.have.length.be(0)
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(0)

      Weaver.Node.load(foo.id())
    ).then((n) ->
      loadedNode = n
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(0)
      expect(loadedNode.relation('comesBefore').allRecords()).to.have.length.be(0)
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(0)
    )

  it 'should remove one of some relation', ->
    loadedNode = undefined
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    relA = foo.relation('comesBefore').add(bar)
    relB = foo.relation('comesBefore').add(bar)
    expect(foo.relation('comesBefore').all()).to.have.length.be(2)
    expect(foo.relation('comesBefore').allRecords()).to.have.length.be(2)
    expect(foo.relation('comesBefore').all()).to.have.length.be(2)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((n) ->
      loadedNode = n
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(2)
      expect(loadedNode.relation('comesBefore').allRecords()).to.have.length.be(2)
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(2)

      loadedNode.relation('comesBefore').removeRelation(relA)
    ).then( ->
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(1)
      expect(loadedNode.relation('comesBefore').allRecords()).to.have.length.be(1)
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(1)

      Weaver.Node.load(foo.id())
    ).then((n) ->
      loadedNode = n
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(1)
      expect(loadedNode.relation('comesBefore').allRecords()).to.have.length.be(1)
      expect(loadedNode.relation('comesBefore').all()).to.have.length.be(1)
    )

  it 'should remove and update a relation with only if first ever', ->
    node = new Weaver.Node()
    c = new Weaver.Node()

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedNode.relation('link').only(c)
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      ids = (i.id() for i in loadedNode.relation('link').all())
      expect(ids).to.have.length.be(1)
      expect(ids[0]).to.equal(c.id())
    )

  it 'should remove and update a relation with only if others where there', ->
    node = new Weaver.Node()
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()
    node.relation('link').add(a)
    node.relation('link').add(b)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedNode.relation('link').only(c)
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      ids = (i.id() for i in loadedNode.relation('link').all())
      expect(ids).to.have.length.be(1)
      expect(ids[0]).to.equal(c.id())
    )

  it 'should keep a relation with only', ->
    node = new Weaver.Node()
    c = new Weaver.Node()
    rel = node.relation('link').add(c)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedNode.relation('link').only(c)
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      relIds = (record.relNode.id() for record in loadedNode.relation('link').allRecords())
      expect(relIds).to.have.length.be(1)
      expect(relIds[0]).to.equal(rel.id())
    )

  it 'should add a relation with only once', ->
    node = new Weaver.Node()
    to = new Weaver.Node()

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      loadedNode.relation('link').onlyOnce(to)
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      ids = (i.id() for i in loadedNode.relation('link').all())
      expect(ids).to.have.length.be(1)
      expect(ids[0]).to.equal(to.id())
    )

  it 'should keep precisely one with only once', ->
    node = new Weaver.Node()
    to = new Weaver.Node()
    node.relation('link').add(to)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      expect(loadedNode.relation('link').all()).to.have.length.be(1)
      loadedNode.relation('link').onlyOnce(to)
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      ids = (i.id() for i in loadedNode.relation('link').all())
      expect(ids).to.have.length.be(1)
      expect(ids[0]).to.equal(to.id())
    )

  it 'should remove too many with only once', ->
    node = new Weaver.Node()
    to = new Weaver.Node()
    node.relation('link').add(to)
    node.relation('link').add(to)
    node.relation('link').add(to)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      expect(loadedNode.relation('link').all()).to.have.length.be(3)
      loadedNode.relation('link').onlyOnce(to)
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      ids = (i.id() for i in loadedNode.relation('link').all())
      expect(ids).to.have.length.be(1)
      expect(ids[0]).to.equal(to.id())
    )

  it 'should load all nodes in the relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    ono = new Weaver.Node()
    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').add(ono)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then(->
      assert.isFalse(node._loaded) for node in foo.relation('comesBefore').all()
      foo.relation('comesBefore').load()
    ).then((nodes) ->
      # assert.isTrue(node._loaded) for node in nodes
      # assert.isTrue(node._loaded) for node in foo.relation('comesBefore').all()
    )

  it 'should return the first node in a relation', ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    ono = new Weaver.Node()

    assert.isUndefined(foo.relation('comesBefore').first())

    foo.relation('comesBefore').add(bar)
    foo.relation('comesBefore').add(ono)

    assert.equal(foo.relation('comesBefore').first(), bar)

  it 'should support relations on relations', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()
    relationNode = a.relation('test').add(b)
    relationNode.relation('relationRelation').add(c)
    a.save().then(->
      Weaver.Node.load(relationNode.id(), undefined, undefined, true)
    ).then((node) ->
      expect(node.relation('relationRelation')).to.have.property('nodes').to.have.length.be(1)
    )

  it.skip 'should use the given constructor, if supplied during Weaver.Relation.prototype.load', ->
    j = {}

    class Person extends Weaver.Node
      age: ->
        @.get('age')

    johnny = new Person('johnny')
    tim = new Person('tim')

    johnny.set('name','Johnny')
    tim.set('name','Timothy')

    johnny.relation('hasFriend').add(tim)
    johnny.save().then(->
      Weaver.Node.load('johnny')
    ).then((_j)->
      j = _j
      j.relation('hasFriend').load(Person)
    ).then(->
      expect(j.relation('hasFriend').first().constructor.name).to.equal('Person')
    )

  describe 'with graphs', ->
    a  = new Weaver.Node('a', 'relationWithGraph1')
    b  = new Weaver.Node('b', 'relationWithGraph1')
    af = new Weaver.Node('a', 'relationWithGraph2')

    b.relation('test').add(a)
# This relation can't be created here because of:
#    http://jira.sysunite.com/browse/WEAV-251
#
#    b.relation('test').add(af)

    before ->
      Weaver.Node.batchSave([a, b, af]).then(->
        b.relation('test').add(af)
        b.save()
      )

    it 'should allow relations to the same node id in different graphs', ->
      expect(Weaver.Node.loadFromGraph('b', 'relationWithGraph1').then((node) ->
        node.relation('test').all()
      )).to.eventually.have.length.be(2)

    it 'should be able to get the relation node for both relations', ->
      Weaver.Node.loadFromGraph('b', 'relationWithGraph1').then((node) ->
        rel = node.relation('test')
        Promise.all([ rel.to(a), rel.to(af) ])
      ).then((res) ->
        expect(res[0].id()).to.not.equal(res[1].id())
      )
