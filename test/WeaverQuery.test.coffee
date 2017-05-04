weaver = require("./test-suite")
Weaver = weaver.getClass()

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
        expect(nodes[0].id()).to.equal("a")
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
        expect(nodes[0].id()).to.equal("a")
        expect(nodes[1].id()).to.equal("c")
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
        expect(nodes[0].id()).to.equal("a")
      )
    ).then(->
      new Weaver.Query()
      .restrict("a")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        expect(nodes[0].id()).to.equal("a")
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
        expect(nodes[0].id()).to.equal("a")
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
        expect(nodes[0].id()).to.equal("b")
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
        expect(nodes[0].id()).to.equal("a")
      )

      new Weaver.Query()
      .hasRelationIn("link", a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        expect(nodes[0].id()).to.equal("b")
      )

      new Weaver.Query()
      .hasNoRelationOut("link", b)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        expect(nodes[0].id()).to.equal("b")
        expect(nodes[1].id()).to.equal("c")
      )

      new Weaver.Query()
      .hasNoRelationIn("link", a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        expect(nodes[0].id()).to.equal("a")
        expect(nodes[1].id()).to.equal("c")
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
