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
  removed = new Weaver.Node()
  fromRemoved = new Weaver.Node()

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

  removed.set('description', 'doa')
  removed.set('testset', '3')
  removedRef = {}
  removedRef2 = {}
  removed.relation('test').add(fromRemoved)
  fromRemoved.relation('test').add(removed)


  ###

  So, we have:
    a -> b -> c -> d -> e
    and,
    a -> e

  ###

  before ->
    wipeCurrentProject().then( ->
      Weaver.Node.batchSave([a, removed])
    ).then(->
      Weaver.Node.load(removed.id())
    ).then((res) ->
      removedRef = res
      Weaver.Node.load(removed.id())
    ).then((res) ->
      removedRef2 = res
      removed.destroy()
    )

  it 'allow writing attributes to deleted nodes', ->
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

  it 'allows writing relations from deleted nodes', ->
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

  it 'allows writing relations to deleted nodes', ->
    ay = {}
    bee = {}

    Weaver.Node.load('a').then((res)->
      ay = res # ay is now another reference to the node a
      Weaver.Node.load('b')
    ).then((res)->
      bee = res
      b.destroy()
    ).then(->
      ay.relation('test').add(bee)
      ay.save()
    ).then(->
      expect(Weaver.Node.load('b')).to.be.rejected # throws 101 (obviously)
    )

  it 'should not allow writing relations to deleted nodes (using the reference of the client-deleted node, as opposed to the client- valid reference for the server-deleted node)', ->
    ay = {}

    Weaver.Node.load('a').then((res)->
      ay = res # ay is now another reference to the node a
      b.destroy()
      expect(-> ay.relation('test').add(b)).to.throw()
    )

  it 'allows destroys on destroyed nodes', ->
    expect(removed.destroy()).to.not.be.rejected

  it 'allows destroys on references to destroyed nodes', ->
    expect(removedRef.destroy()).to.not.be.rejected

  it 'does not allow setting attributes on destroyed nodes', ->
    expect( -> removed.set('a', 'b')).to.throw()

  it 'allows setting attributes on destroyed node references', ->
    removedRef2.set('a', 'b')
    expect(removedRef2.save()).to.not.be.rejected

  it 'does not allow setting relations from destroyed nodes', ->
    expect( -> removed.relation('test').add(a)).to.throw()

  it 'allows setting relations from destroyed node references', ->
    removedRef2.relation('test').add(a)
    expect(removedRef2.save()).to.not.be.rejected

  it 'does not allow setting relations to destroyed nodes', ->
    expect( -> a.relation('test').add(removed)).to.throw()

  it 'allows setting relations to destroyed node references', ->
    a.relation('test').add(removedRef2)
    expect(a.save()).to.not.be.rejected

  it 'does not allow attribute removal on destroyed nodes', ->
    expect(-> removed.unset('description')).to.throw()

  it 'allows attribute removal on destroyed node references', ->
    removedRef2.unset('description')
    expect(removedRef2.save()).to.not.be.rejected

  it 'does not allow relation removal on destroyed nodes', ->
    expect(-> removed.relation('test').remove(fromRemoved)).to.throw()

  it 'allows relation removal on destroyed node references', ->
    removedRef2.relation('test').remove(fromRemoved)
    expect(removedRef2.save()).to.not.be.rejected
