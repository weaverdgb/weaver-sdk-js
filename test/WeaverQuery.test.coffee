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

  it 'should do equalTo a double', ->
    a = new Weaver.Node("a")
    a.set("name", "Project A")
    a.set("age", 44)
    b = new Weaver.Node("b")
    b.set("name", "Project B")
    b.set("age", 20.4)
    c = new Weaver.Node("c")
    c.set("age", 44.4)
    d = new Weaver.Node("d")
    d.set("notAge", 44)


    Promise.all([a.save(), b.save(), c.save(), d.save()]).then(->
      new Weaver.Query()
      .equalTo("age", 44)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

      new Weaver.Query()
      .equalTo("age", 20.4)
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
      .withRelations()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )
    )

  it 'should default to not returning relations', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    a.relation("to").add(b, "c")

    a.save().then(->
      new Weaver.Query()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )
    )

  it 'should not return relations when noRelations is set', ->
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

  it 'should do relation hasRelationOut', ->
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
    )


  it 'should do relation hasRelationIn', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    a.relation("link").add(b)

    Promise.all([a.save(), c.save()]).then(->

      new Weaver.Query()
      .hasRelationIn("link", a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
      )
    )


  it 'should do relation hasNoRelationOut', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    a.relation("link").add(b)

    Promise.all([a.save(), c.save()]).then(->

      new Weaver.Query()
      .hasNoRelationOut("link", b)
      .withRelations()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )
    )


  it 'should do relation hasNoRelationIn', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    a.relation("link").add(b)

    Promise.all([a.save(), c.save()]).then(->
      new Weaver.Query()
      .noRelations()
      .hasNoRelationIn("link")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )
    )

  it 'should do specific relation hasNoRelationIn', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    a.relation("link").add(b)

    Promise.all([a.save(), c.save()]).then(->
      new Weaver.Query()
      .noRelations()
      .hasNoRelationIn("link", a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )
    )



  it 'should deny any other user than root to execute a native query', ->
    query = "select * where { ?s ?p ?o }"
    q = new Weaver.Query()

    user = new Weaver.User("username", "centaurus123", "centaurus@univer.se")
    user.create()
    .then(->
      weaver.currentProject().getACL()
    ).then((projectACL) ->
      projectACL.setUserReadAccess(user, true)
      projectACL.setUserWriteAccess(user, true)
      projectACL.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername("username", "centaurus123")
    ).then(->
      q.nativeQuery(query)
    ).then(->
       assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should allow for sorting', ->
    a = new Weaver.Node("a")
    a.set("name", "a")
    a.set("special", "abcdef")
    c = new Weaver.Node("c")
    c.set("name", "c")
    c.set("special", "klmno")
    b = new Weaver.Node("b")
    b.set("name", "b")
    b.set("special", "uvwxyz")

    Promise.all([a.save(), c.save(), b.save()]).then(->
      new Weaver.Query()
      .noRelations()
      .ascending(['name'])
      .find().then((nodes) ->
        (i.attributes.name[0].value for i in nodes).should.eql(['a', 'b', 'c'])

      )
    )

  it.skip 'should return all relations even on attribute selects', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    a.set("name", "a name")
    a.set("description", "a desc")
    a.set("skip", "a skip")
    a.relation('link').add(b)

    a.save().then(->
      new Weaver.Query()
      .select('name', 'description')
      .restrict(['a'])
      .find().then((nodes)->
        expect(nodes).to.have.length.be(1)
        checkNodeInResult(nodes, 'a')
        expect(nodes[0]).to.have.property('relations').to.have.property('link').to.have.length.be(1)
      )
    )

  it.skip 'should allow attribute selects', ->
    a = new Weaver.Node('a')
    a.set("name", "a name")
    a.set("description", "a desc")
    a.set("skip", "a skip")

    a.save().then(->
      new Weaver.Query()
      .select('name', 'description')
      .find().then((nodes)->
        expect(nodes).to.have.length.be(1)
        checkNodeInResult(nodes, 'a')
        attrs = nodes[0].attributes
        expect(attrs).to.have.property('name')
        expect(attrs).to.have.property('description')
        expect(attrs).to.not.have.property('skip')
      )
    )

  it 'skips relation out value if an array is provided', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    a.relation('linkA').add(b)

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut(['linkA'], 'c')
      .find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )
    )

  it 'should allow "or" in predicates for hasRelationOut', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')

    a.relation('linkA').add(b)
    b.relation('linkB').add(c)
    c.relation('linkC').add(a)

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut(['linkA','linkB'])
      .find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )
    )

  it 'should allow "or" in objects for specific hasRelationOut', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')

    a.relation('link').add(b)
    b.relation('link').add(c)
    c.relation('link').add(a)

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link',[ Weaver.Node.get('b'), Weaver.Node.get('c')])
      .find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )
    )

  it.skip 'should load in some secondary nodes with "selectOut"', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')
    a.relation('link').add(b)
    a.relation('test').add(c)
    c.set('name', 'bravo')

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link')
      .selectOut('test') # selectOut is optional, it loads the attrs/rels for node c if node a has a 'test' relation to node c,
                         # but does not exclude node a from the result set if node a does not have this relation
      .find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
        expect(nodes[0].relation('test').nodes[c].get('name')).to.equal('bravo')
      )
    )

  it.skip 'should ensure that nodes are not excluded based on the  "selectOut" flag', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')
    d = new Weaver.Node('d')
    a.relation('link').add(b)
    b.relation('link').add(d)
    a.relation('test').add(c)
    c.set('name', 'bravo')

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link')
      .selectOut('test')
      .find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )
    )

  it.skip 'should load in some secondary nodes with "selectIn"', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')

    a.relation('test').add(b)
    b.relation('link').add(c)
    a.set('name','alpha')

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link')
      .selectIn('test')
      .find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
        expect(nodes[0].relationIn('test').nodes[a].get('name')).to.equal('alpha')
      )
    )

  it.skip 'should ensure that nodes are not excluded based on the  "selectIn" flag', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')
    d = new Weaver.Node('d')
    a.relation('test').add(b)
    b.relation('link').add(c)
    c.relation('link').add(d)

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link')
      .selectIn('test')
      .find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )
    )

  it.skip 'should be able to do nested queries (to allow hops)', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')
    a.relation('link').add(b)
    b.relation('link').add(c)

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link',
        new Weaver.Query().hasRelationOut('link')
      ).find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )
    )

  it.skip 'should also load secondary nodes in nested queries', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')
    b.set('name', 'bravo')
    a.relation('link').add(b)
    b.relation('link').add(c)

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link',
        new Weaver.Query().hasRelationOut('link')
      ).find().then((nodes)->
        expect(nodes[0].relation('link').nodes['b'].get('name')).to.equal('bravo')
      )
    )

  it.skip 'should allow optional relations in queries', ->
    a = new Weaver.Node()
    b = new Weaver.Node()

    a.relation('link').add(b)

    a.save().then(->
      new Weaver.Query()
      .hasOptionalRelationOut('link')
      .find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )
    )

  it.skip 'should allow optional relations in nested queries', ->
    a1 = new Weaver.Node('a1')
    b1 = new Weaver.Node('b1')
    c1 = new Weaver.Node('c1')
    a2 = new Weaver.Node('a2')
    b2 = new Weaver.Node('b2')
    c2 = new Weaver.Node('c2')

    x  = new Weaver.Node('x')

    a1.relation('link').add(b1)
    a1.relation('required').add(x)
    b1.relation('valid').add(c1)
    b1.set('name','bravo-one')

    a2.relation('link').add(b2)
    a2.relation('required').add(x)
    b2.relation('invalid').add(c2)
    b2.set('name','bravo-two')

    Promise.all([a1.save(), a2.save()]).then(->

      new Weaver.Query()
      .hasRelationOut('required', Weaver.Node.get('x'))
      .hasOptionalRelationOut('link',
        new Weaver.Query().hasRelationOut('valid')
      ).find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a1')
        checkNodeInResult(nodes, 'a2')
        # make sure the 'name' attribute for b1 is loaded, and not loaded for b2
        for node in nodes
          if node.id() is 'a1'
            expect(node.relation('link').nodes['b1'].get('name')).to.equal('bravo-one')
          if node.id() is 'a2'
            expect(node.relation('link').nodes['b2'].get('name')).to.equal(undefined)
      )
    )

  it.skip 'should do a badass query', ->
    promises = []

    spaceType       = new Weaver.Node('SpaceType')
    spaceGroupType  = new Weaver.Node('SpaceGroupType')
    space1          = new Weaver.Node('space1')
    space2          = new Weaver.Node('space2')
    space3          = new Weaver.Node('space3')
    connectionNode1 = new Weaver.Node('space1Conn')
    connectionNode2 = new Weaver.Node('space2Conn')
    spaceGroup1     = new Weaver.Node('spaceGroup1')
    spaceGroup2     = new Weaver.Node('spaceGroup2')
    spaceGroup3     = new Weaver.Node('spaceGroup3')
    spaceReq1       = new Weaver.Node('spaceRequirement1')

    space1.relation('type').add(spaceType)
    space2.relation('type').add(spaceType)
    space3.relation('type').add(spaceType)
    spaceGroup1.relation('type').add(spaceGroupType)
    spaceGroup2.relation('type').add(spaceGroupType)
    spaceGroup3.relation('type').add(spaceGroupType)

    spaceGroup1.relation('consistsOf').add(spaceGroup2)
    spaceGroup2.relation('consistsOf').add(spaceGroup3)
    spaceGroup3.relation('consistsOf').add(connectionNode1)
    spaceGroup3.relation('consistsOf').add(connectionNode2)
    connectionNode1.relation('to').add(space1)
    connectionNode2.relation('to').add(space2)
    space1.relation('hasSpaceRequirement').add(spaceReq1)
    space2.relation('hasSpaceRequirement').add(spaceReq1)

    spaceReq1.set('name','SpaceRequirementOne')

    spaceGroup1.save().then(->
      new Weaver.Query()
      .hasRelationOut('type', [Weaver.Node.get('SpaceType'), Weaver.Node.get('SpaceGroupType')])
      .selectOut(['hasSpaceRequirement', 'consistsOf'])
      .selectIn(['consistsOf'])
      .optionalRelationIn('to',
        new Weaver.Query().hasRelationIn('consistsOf'),
      ).optionalRelationOut('consistsOf',
        new Weaver.Query().hasRelationOut('to')
      ).find().then((nodes)->
        expect(nodes.length).to.equal(6)
        for node in nodes
          switch(node.id())
            when 'space1'
              expect(node.relation('hasSpaceRequirement').nodes['spaceReq1'].get('name')).to.equal('SpaceRequirementOne')
            when 'space2'
              expect(node.relationIn('to').nodes['spaceConn2'].relationIn('consistsOf').nodes['spaceGroup3'])
            when 'spaceGroup2'
              expect(node.relationOut('consistsOf').nodes['spaceGroup3'].relationOut('consistsOf').nodes['spaceConn1'])
      )
    )

