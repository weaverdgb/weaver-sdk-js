weaver = require("./test-suite")
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverQuery Test', ->

  it 'should restrict to a single node', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")

    Promise.all([a.save(), b.save(), c.save()]).then(->
      new Weaver.Query()
      .restrict(a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )
    )

  it 'should restrict to multiple nodes', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")

    Promise.all([a.save(), b.save(), c.save()]).then(->
      new Weaver.Query()
      .restrict([a,c])
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )
    )

  it 'should count', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")

    Promise.all([a.save(), b.save(), c.save()]).then(->
      new Weaver.Query()
      .restrict([a,c])
      .count().then((count) ->
        expect(count).to.equal(2)
      )
    )

  it 'should take an array of nodeIds or nodes, or single nodeId or node into restrict', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")

    Promise.all([a.save(), b.save()]).then(->
      new Weaver.Query()
      .restrict(a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )
    ).then(->
      new Weaver.Query()
      .restrict("a")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )
    ).then(->
      new Weaver.Query()
      .restrict([a,b])
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
      )
    ).then(->
      new Weaver.Query()
      .restrict(["a", "b"])
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
      )
    )

  it 'should do equalTo a boolean', ->
    a = new Weaver.Node("a")
    a.set("isRed", true)
    b = new Weaver.Node("b")
    b.set("isRed", false)
    c = new Weaver.Node("c")
    c.set("isBlue", true)

    Promise.all([a.save(), b.save(), c.save()]).then(->
      new Weaver.Query()
      .equalTo("isRed", true)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )
    )

  it 'should do equalTo a string', ->
    a = new Weaver.Node("a")
    a.set("name", "Project A")
    b = new Weaver.Node("b")
    b.set("name", "Project B")
    c = new Weaver.Node("c")

    Promise.all([a.save(), b.save(), c.save()]).then(->
      new Weaver.Query()
      .equalTo("name", "Project B")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
      )
    )

  it 'should do contains of a string', ->
    a = new Weaver.Node("a")
    a.set("name", "Project A")
    a.set("special", "abcdef")
    b = new Weaver.Node("b")
    b.set("name", "Project B")
    b.set("special", "uvwxyz")
    c = new Weaver.Node("c")
    c.set("name", "project ")
    c.set("special", "klmno")

    Promise.all([a.save(), b.save(), c.save()]).then(->
      new Weaver.Query()
      .contains("name", "c")
      .contains("special", "o")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'c')
      )
    )

  it 'should return relations', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    a.relation("to").add(b, "c")

    a.save().then(->
      new Weaver.Query()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )
    )

  it 'should not return relations', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    a.relation("to").add(b, "c")

    a.save().then(->
      new Weaver.Query()
      .noRelations()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )
    )

  it 'should do relation check a relation', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    a.relation("link").add(b)


    Promise.all([a.save(), c.save()]).then(->

      new Weaver.Query()
      .hasRelationOut("link", b)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

      new Weaver.Query()
      .hasRelationIn("link", a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
      )

      new Weaver.Query()
      .hasNoRelationOut("link", b)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )

      new Weaver.Query()
      .hasNoRelationIn("link", a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )
    )

  it 'should run a native query', ->

    query = "select * where { ?s ?p ?o }"

    q = new Weaver.Query()
    q.nativeQuery(query).then((res)->
      assert.include(res.head.vars, 's')
      assert.include(res.head.vars, 'p')
      assert.include(res.head.vars, 'o')
    )
