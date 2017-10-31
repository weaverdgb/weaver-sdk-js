weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

weaver._ignoresOutOfDate = true

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'Weaver idiosyncracies examination', ->
  a = new Weaver.Node('a')
  b = new Weaver.Node('b')
  c = new Weaver.Node('c')
  d = new Weaver.Node('d')
  e = new Weaver.Node('e')

  a.relation('requires').add(b)
  a.set('name', 'Ay')
  a.set('theme', 'node')
  a.set('testset', '1')

  b.set('description', 'Be, Bee')
  b.set('endangered', 'true')
  b.set('testset', '2')

  c.set('description', 'Sea')
  c.set('realDescription', 'deep')
  c.set('testset', '2')

  d.set('description', 'Dei')
  d.set('isHoly', 'yes')
  d.set('testset', '2')

  a.relation('preceeds').add(b)
  b.relation('preceeds').add(c)
  c.relation('preceeds').add(d)
  d.relation('preceeds').add(e)

  a.relation('&').add(e)

  ###

  So, we have:
    a -> b -> c -> d -> e
    and,
    a -> e

  ###

  before ->
    wipeCurrentProject().then( ->
      Promise.all([a.save()])
    )

  it 'Should (or not?) allow writing attributes to deleted nodes', ->
    dei = {}

    Weaver.Node.load('d').then((res)->
      dei = res # dei is now another reference to the node d
      d.destroy()
    ).then(->
      dei.set('is-now', 'non-existent')
      dei.save() # runs without exception
    ).then((res)->
      expect(Weaver.Node.load('d')).to.be.rejected # throws 101 (obviously)
    )

  it 'Should (or not?) allow writing relations from deleted nodes', ->
    sea = {}

    Weaver.Node.load('c').then((res)->
      sea = res # sea is now another reference to the node c
      c.destroy()
    ).then(->
      sea.relation('will-no-longer-sooth').add(b)
      sea.save() # runs without exception
    ).then((res)->
      expect(Weaver.Node.load('c')).to.be.rejected # throws 101 (obviously)
    )
  it 'Should (or not?) allow writing relations to deleted nodes', ->
    ay = {}

    Weaver.Node.load('a').then((res)->
      ay = res # ay is now another reference to the node a
      b.destroy()
    ).then(->
      ay.relation('test').add(b)
      ay.save() # this fails
    ).then((res)->
      expect(Weaver.Node.load('b')).to.be.rejected # throws 101 (obviously)
    )
