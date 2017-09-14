weaver = require("./test-suite")
Weaver = require('../src/Weaver')

describe 'WeaverNodeRules test', ->

  it 'should read the root node', ->
    root = Weaver.Root()

    assert.equal(root.id(), 'root')


  it 'should force a relation', ->
    a = new Weaver.Node()
    b = new Weaver.Node()

    a.relation('link').addAllowed(b)                      # internally creates a rule and then the relation
    a.save().then(->
      assert(true)
    )


  it 'should create a rule and a relation', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()


    a.relation('link').allow(b)
    a.relation('link').add(b)
    a.save().then(->
      assert(true)

      a.relation('link').add(c)
      a.save()
    ).then(->
      assert(false)
    )

  it 'should create a rule and a relation', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()


    a.relation('link').allow(Weaver.Root())
    a.relation('link').add(b)
    a.relation('link').add(c)
    a.save().then(->
      assert(true)
    )


  it 'should force a new string attribute', ->
    node = new Weaver.Node()

    node.setAllowed('name', 'Foo')

    node.save().then(->
      assert(true)
    )

  it 'should force a new string attribute', ->
    node = new Weaver.Node()

    node.allow('name', datatype.string)
    node.set('name', 'Foo')

    node.save().then(->
      assert(true)
    )


  it 'should support inheritance', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    b.extends(a)

    b.save().then(->
      assert(true)
    )

  it 'should support breaking inheritance', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    b.extends(a)

    b.save().then(->
      b.leave(a)

    ).then(->
      assert(true)
    )


