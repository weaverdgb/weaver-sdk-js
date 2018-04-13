weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'WeaverRelationMeta test', ->
  a = new Weaver.Node()
  b = new Weaver.Node()
  d = new Weaver.Node()
  a.relation('link').add(b)
  relationNode = {}

  before ->
    Weaver.Node.batchSave([a, d]).then( ->
      a.relation('link').to(b)
    ).then((rn) ->
      relationNode = rn
    )

  it 'should allow loading a relataion and adding an attribute on it', ->
    new Weaver.Query()
      .withRelations()
      .restrict(relationNode)
      .first()
    .then((node) ->
      node.set('someattr', 'd')
      node.save()
    )

  it 'should allow saving nodes with a relation to saved nodes', ->
    new Weaver.Query()
      .restrict(a.id())
      .first()
    .then((loadedA) ->
      c = new Weaver.Node()
      c.relation('other').add(a)
      c.save()
    )

  it 'should allow saving relations on relations', ->
    d.relation('test').add(a)
    d.save().then( ->
      Promise.all([ d.relation('test').to(a), Weaver.Node.load(b.id()) ])
    ).then((results) ->
      results[0].relation('anothertest').add(results[1])
      results[0].save()
    ).then(->
      new Weaver.Query()
        .withRelations()
        .restrict(b.id())
        .first()
    )



