weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverQuery Test', ->

  describe 'clean nodes, without links', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    d = new Weaver.Node("d", "d-graph")

    before ->
      wipeCurrentProject().then( ->
        Promise.all([a.save(), b.save(), c.save(), d.save()])
      )

    it 'should restrict to a single node', ->
      new Weaver.Query()
      .restrict(a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should throw error with emtpy array restrict', ->
      expect(-> new Weaver.Query().restrict([])).to.throw

    it 'should restrict to multiple nodes', ->
      new Weaver.Query()
      .restrict([a,c])
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )

    it 'should find all nodes', ->
      new Weaver.Query()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(4)
      )

    it 'should restrict nodes with createdBy constraint', ->
      new Weaver.Query()
        .createdBy(Weaver.getInstance().currentUser())
        .find()
        .then((nodes) ->
          expect(nodes.length).to.equal(4)
          otherUser = new Weaver.User('other', 'user')
          new Weaver.Query()
            .createdBy(otherUser)
            .find()
        ).then((nodes) ->
          expect(nodes.length).to.equal(0)
        )

    it 'should count', ->
      new Weaver.Query()
      .restrict([a,c])
      .count().then((count) ->
        expect(count).to.equal(2)
      )

    it 'should count per graph', ->
      new Weaver.Query()
      .countPerGraph().then((res) ->
        expect(res.count).to.equal(4)
        expect(res.defaultGraph).to.equal(3)
        expect(res.graphs['d-graph']).to.equal(1)
      )

      new Weaver.Query()
      .restrict([a,c])
      .countPerGraph().then((res) ->
        expect(res.count).to.equal(2)
        expect(res.defaultGraph).to.equal(2)
      )

      new Weaver.Query()
      .hasRelationOut('link')
      .countPerGraph().then((res) ->
        expect(res.count).to.equal(0)
        expect(res.defaultGraph).to.equal(0)
      )

    it 'should return relations', ->
      a.relation("to").add(b, "c")

      new Weaver.Query()
      .withRelations()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(4)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
        checkNodeInResult(nodes, 'd')
      )

    it 'should take an array of nodeIds or nodes, or single nodeId or node into restrict', ->
      new Weaver.Query()
      .restrict(a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )
      .then(->
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

  describe 'clean nodes, with a-b link-relation', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")

    before ->
      wipeCurrentProject().then( ->
        a.relation("link").add(b)
        Promise.all([a.save(), b.save(), c.save()])
      )


    it 'should do relation hasRelationOut without supplying a node', ->
      new Weaver.Query()
      .hasRelationOut("link")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should do relation hasRelationOut', ->
      new Weaver.Query()
      .hasRelationOut("link", b)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should do relation hasRelationOut with id argument', ->
      new Weaver.Query()
      .hasRelationOut("link", "b")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should do relation hasRelationIn without supplying a node', ->
      new Weaver.Query()
      .hasRelationIn("link")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
      )

    it 'should do relation hasRelationIn', ->
      new Weaver.Query()
      .hasRelationIn("link", a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
      )

    it 'should do relation hasRelationIn with id argument', ->
      new Weaver.Query()
      .hasRelationIn("link", "a")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
      )


    it 'should do relation hasNoRelationOut without relations', ->
      new Weaver.Query()
      .hasNoRelationOut("link", b)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )

    it 'should do relation hasNoRelationOut without relations with id argument', ->
      new Weaver.Query()
      .hasNoRelationOut("link", "b")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )

    it 'should do relation hasNoRelationOut', ->
      new Weaver.Query()
      .hasNoRelationOut("link", b)
      .withRelations()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )

    it 'should do relation hasNoRelationOut with id argument', ->
      new Weaver.Query()
      .hasNoRelationOut("link", "b")
      .withRelations()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        checkNodeInResult(nodes, 'b')
      )

    it 'should do relation hasNoRelationIn', ->
      new Weaver.Query()
      .noRelations()
      .hasNoRelationIn("link")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )

    it 'should do relation hasNoRelationIn with id argument', ->
      new Weaver.Query()
      .noRelations()
      .hasNoRelationIn("link")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )

    it 'should do specific relation hasNoRelationIn', ->
      new Weaver.Query()
      .noRelations()
      .hasNoRelationIn("link", a)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )

    it 'should do specific relation hasNoRelationIn with id argument', ->
      new Weaver.Query()
      .noRelations()
      .hasNoRelationIn("link", "a")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )

  describe 'clean nodes, with a-b,"c" to-relation', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")

    before ->
      wipeCurrentProject().then( ->
        a.relation("to").add(b, "c")
        a.save()
      )

    it 'should default to not returning relations', ->
      new Weaver.Query()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )

    it 'should not return relations when noRelations is set', ->
      new Weaver.Query()
      .noRelations()
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )

  describe 'clean nodes, with a-b and meta to-relation', ->

    beforeEach ->
      wipeCurrentProject()

    it 'should return also relation on relation when query', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')

      relNode = a.relation('to').add(b)
      relNodeId = relNode.id()
      assert.isTrue(relNode instanceof Weaver.RelationNode)
      relNode.relation('meta').add(c)
      a.save()
      .then(->
        new Weaver.Query()
        .withRelations()
        .find().then((nodes) ->
          expect(nodes.length).to.equal(5)
          checkNodeInResult(nodes, 'a')
          checkNodeInResult(nodes, 'b')
          checkNodeInResult(nodes, 'c')
          for node in nodes
            if node.id() is relNodeId
              assert.isTrue(node instanceof Weaver.RelationNode)
              assert.isTrue(node.fromNode instanceof Weaver.Node)
              assert.isTrue(node.toNode instanceof Weaver.Node)
              expect(node.key).to.equal("to")
        )
      )

    it 'should return also relation on relation when relation out query', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b', 'special')
      c = new Weaver.Node('c')

      relNode = a.relation('to').add(b)
      relNodeId = relNode.id()
      assert.isTrue(relNode instanceof Weaver.RelationNode)
      relNode.relation('meta').add(c)
      a.save()
      .then(->
        new Weaver.Query()
        .withRelations()
        .hasRelationOut('meta')
        .find().then((nodes) ->
          expect(nodes.length).to.equal(1)
          assert.isTrue(nodes[0] instanceof Weaver.RelationNode)
          assert.isTrue(nodes[0].fromNode instanceof Weaver.Node)
          expect(nodes[0].fromNode.id()).to.equal('a')
          assert.isTrue(nodes[0].toNode instanceof Weaver.Node)
          expect(nodes[0].toNode.id()).to.equal('b')
          expect(nodes[0].toNode.getGraph()).to.equal('special')
        )
      )

  describe 'clean nodes, with a-b-c named link-relations', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')

    before ->
      wipeCurrentProject().then( ->
        a.relation('linkA').add(b)
        b.relation('linkB').add(c)
        c.relation('linkC').add(a)
        a.save()
      )

    it 'should allow "or" in predicates for hasNoRelationIn', ->
      new Weaver.Query()
      .hasNoRelationIn(['linkA','linkB'])
      .find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should allow "or" in predicates for hasNoRelationOut', ->
      new Weaver.Query()
      .hasNoRelationOut(['linkA','linkB'])
      .find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'c')
      )

    it 'should allow "or" in predicates for hasRelationIn', ->
      new Weaver.Query()
      .hasRelationIn(['linkA','linkB'])
      .find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )

    it 'should allow "or" in predicates for hasRelationOut', ->
      new Weaver.Query()
      .hasRelationOut(['linkA','linkB'])
      .find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )

  describe 'clean nodes, with a-b b-c a-c link-relations', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')

    before ->
      wipeCurrentProject().then( ->
        a.relation('link').add(b)
        b.relation('link').add(c)
        a.relation('link').add(c)
        a.save()
      )

    it 'should support hasRelationOut hasNoRelationOut on the same key with a defined target', ->
      expect(new Weaver.Query()
      .hasRelationOut('link')
      .hasNoRelationOut('link', 'b')
      .find()).to.eventually.have.length.be(1)

  describe 'clean nodes, with a-b b-c link-relations', ->
    a = new Weaver.Node('a')
    b = new Weaver.Node('b')
    c = new Weaver.Node('c')

    before ->
      wipeCurrentProject().then( ->
        a.relation('link').add(b)
        b.relation('link').add(c)
        b.relation('redundant').add(c)
        a.save()
      )

    it 'should support hasRelationOut hasNoRelationIn on same key', ->
      expect(new Weaver.Query()
      .hasRelationOut('link')
      .hasNoRelationIn('link')
      .find()).to.eventually.have.length.be(1)

    it 'should support hasNoRelationOut hasRelationIn on same key', ->
      expect(new Weaver.Query()
      .hasNoRelationOut('link')
      .hasRelationIn('link')
      .find()).to.eventually.have.length.be(1)

    it 'should combine hasNoRelationOut seperate clauses correctly', ->
      new Weaver.Query()
      .hasNoRelationOut('link', Weaver.Node.get('b'))
      .hasNoRelationOut('redundant', Weaver.Node.get('c'))
      .find().then((nodes) ->
        expect(nodes).to.have.length.be(1)
        checkNodeInResult(nodes, 'c')
      )

    it 'should combine hasNoRelationOut combined clauses correctly', ->
      expect(new Weaver.Query()
        .hasNoRelationOut('link', 'b', 'c')
        .find()).to.eventually.have.length.be(1)

    it 'should be able to do nested queries (to allow hops)', ->
      new Weaver.Query()
      .hasRelationOut('link',
        new Weaver.Query().hasRelationOut('link')
      ).find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should be able to do nested hasRelationIn queries', ->
      new Weaver.Query()
      .hasRelationIn('link',
        new Weaver.Query().hasRelationIn('link')
      ).find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'c')
      )

    it 'should be able to do recursiveRelationOut queries with a target', ->
      new Weaver.Query()
      .hasRecursiveRelationOut('link', Weaver.Node.get('c'))
      .find()
      .then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )

    # WILL NOT BE SUPPORTED
    it.skip 'should be able to do ONLY recursive RelationOut queries with a target', ->
      new Weaver.Query()
      #                         rel,   target,               includesTarget, recursiveOnly
      .hasRecursiveRelationOut('link', Weaver.Node.get('c'), false,          true)
      .find()
      .then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    # WILL NOT BE SUPPORTED
    it.skip 'should be able to do recursiveRelationOut queries without a target', ->
      # return all nodes that have at least two levels of relations out
      new Weaver.Query()
      .hasRecursiveRelationOut('link')
      .find()
      .then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

  describe 'other nodes, requiring wipe before each test', ->
    beforeEach ->
      wipeCurrentProject()

    it 'should allow "or" in objects for specific hasRelationOut', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')

      a.relation('link').add(b)
      b.relation('link').add(c)
      c.relation('link').add(a)

      a.save().then(->
        new Weaver.Query()
        .hasRelationOut('link', Weaver.Node.get('b'), Weaver.Node.get('c'))
        .find().then((nodes)->
          expect(nodes.length).to.equal(2)
          checkNodeInResult(nodes, 'a')
          checkNodeInResult(nodes, 'b')
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

    it 'should do relation hasRelationOut with subclasses', ->
      class SpecialNodeA extends Weaver.Node

      a = new Weaver.Node("a")
      b = new SpecialNodeA("b")
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
          (i.attributes().name for i in nodes).should.eql(['a', 'b', 'c'])
        )
      )

    it 'should not break on loops', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')

      a.relation('x').add(b)
      b.relation('y').add(a)

      Promise.all([a.save(), b.save()]).then(->
        new Weaver.Query().find()
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

    it 'should load in some secondary nodes with "selectOut" while relation does not exist', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      a.relation('link').add(b)
      c.set('name', 'bravo')

      Promise.all([a.save(), c.save()]).then(->
        new Weaver.Query()
        .selectOut('test') # selectOut is optional, it loads the attrs/rels for node c if node a has a 'test' relation to node c,
                          # but does not exclude node a from the result set if node a does not have this relation
        .find().then((nodes)->
          expect(nodes.length).to.equal(3)
          checkNodeInResult(nodes, 'a')
        )
      )

    it 'should load in some secondary nodes with "selectOut"', ->
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
          expect(nodes[0].relation('test').all()[0].get('name')).to.equal('bravo')
        )
      )

    it 'should support multiple hops for selectOut', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      a.relation('link').add(b)
      b.relation('test').add(c)
      c.set('name', 'grazitutti')

      a.save().then(->
        new Weaver.Query()
        .hasRelationOut('link')
        .selectOut('link', 'test')
        .find().then((nodes)->
          expect(nodes.length).to.equal(1)
          checkNodeInResult(nodes, 'a')
          loadedB = nodes[0].relation('link').all()[0]
          expect(loadedB).to.exist
          expect(loadedB.relation('test').all()[0].get('name')).to.equal('grazitutti')
        )
      )

    it 'should support constructors with multiple hops for selectOut', ->
      class SpecialNodeA extends Weaver.Node
      class SpecialNodeB extends Weaver.Node
      class SpecialNodeC extends Weaver.Node

      a = new SpecialNodeA('a')
      a.set('type', 'typeA')
      b = new SpecialNodeB('b')
      b.set('type', 'typeB')
      c = new SpecialNodeC('c')
      c.set('type', 'typeC')
      a.relation('link').add(b)
      b.relation('test').add(c)

      a.save().then(->
        new Weaver.Query()
        .hasRelationOut('link')
        .selectOut('link', 'test')
        .setConstructorFunction((node)->
          if node.get('type') is 'typeA'
            SpecialNodeA
          else if node.get('type') is 'typeC'
            SpecialNodeC
        )
        .find().then((nodes) ->
          expect(nodes.length).to.equal(1)

          loadedA = nodes[0]
          loadedB = nodes[0].relation('link').all()[0]
          loadedC = loadedB.relation('test').all()[0]

          assert.isTrue(loadedA instanceof SpecialNodeA)
          assert.isTrue(loadedB instanceof Weaver.Node)
          assert.isTrue(loadedC instanceof SpecialNodeC)
        )
      )

    it 'should allow multiple selectOut clauses', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      b.set('name', 'Seb')
      c.set('name', 'Lewis')

      a.relation('beats').add(b)
      a.relation('beatenBy').add(c)

      a.save().then( ->
        new Weaver.Query()
        .hasRelationOut('beats')
        .selectOut('beats')
        .selectOut('beatenBy')
        .find()
      ).then((nodes) ->
        expect(nodes).to.have.length.be(1)
        checkNodeInResult(nodes, 'a')
        expect(nodes[0].relation('beats').all()[0].get('name')).to.equal('Seb')
        expect(nodes[0].relation('beatenBy').all()[0].get('name')).to.equal('Lewis')
      )

    it 'should not 503 on selectOut for no nodes', ->
      new Weaver.Query()
      .selectOut('test')
      .find().then((nodes)->
        expect(nodes.length).to.equal(0)
      )

    it 'should ensure that nodes are not excluded based on the  "selectOut" flag', ->
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

    it 'should allow wildcard selectOut', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      a.relation('link').add(b)
      a.relation('test').add(c)
      c.set('name', 'foxtrot')
      b.set('name', 'tango')

      a.save().then(->
        new Weaver.Query()
        .hasRelationOut('link')
        .selectOut('*')
        .find().then((nodes)->
          expect(nodes.length).to.equal(1)
          checkNodeInResult(nodes, 'a')
          expect(nodes[0].relation('test').all()[0].get('name')).to.equal('foxtrot')
          expect(nodes[0].relation('link').all()[0].get('name')).to.equal('tango')
        )
      )

    it 'should support recursive selectOut', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      d = new Weaver.Node('d')
      e = new Weaver.Node('e')
      a.relation('selector').add(b)
      a.relation('rec').add(b)
      b.relation('rec').add(c)
      c.relation('rec').add(d)
      d.relation('rec').add(e)
      e.set('name', 'toprec')
      a.save().then( ->
        new Weaver.Query()
        .hasRelationOut('selector')
        .selectRecursiveOut('rec')
        .find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        expect(nodes[0].relation('rec').all()[0].relation('rec').all()[0].relation('rec').all()[0].relation('rec').all()[0].get('name')).to.equal("toprec")
      )

    it 'should support multiple recursive selectOut relations', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      a.relation('selector').add(b)
      a.relation('rec').add(b)
      b.relation('test').add(c)
      a.save().then( ->
        new Weaver.Query()
        .hasRelationOut('selector')
        .selectRecursiveOut('rec', 'test')
        .find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        expect(nodes[0].relation('rec').all()[0].relation('test').all()[0]).to.exist
      )

    it 'should not break on loops with recursive selectOut', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      a.relation('selector').add(b)
      a.relation('rec').add(b)
      b.relation('rec').add(a)
      a.save().then( ->
        new Weaver.Query()
        .hasRelationOut('selector')
        .selectRecursiveOut('rec')
        .find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        expect(nodes[0].relation('rec').all()[0].relation('rec').all()[0]).to.exist
      )

    it 'should be able to combine hasRelationIn queries with hasRelationOut', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')

      a.relation('link').add(b)
      b.relation('test').add(c)

      Promise.all([a.save()]).then(->
        new Weaver.Query()
          .hasRelationIn('link')
          .hasRelationOut('test')
        .find()
      ).then((nodes)->
          expect(nodes.length).to.equal(1)
          checkNodeInResult(nodes, 'b')
      )

    it 'should be able to combine nested hasRelationIn queries with hasRelationOut', ->
      a = new Weaver.Node('a')
      b = new Weaver.Node('b')
      c = new Weaver.Node('c')
      d = new Weaver.Node('d')

      b.relation('link').add(c)
      c.relation('link').add(a)
      c.relation('test').add(d)

      Promise.all([a.save(), c.save(), b.save()]).then(->
        q = new Weaver.Query()
        .hasRelationIn('link',
          new Weaver.Query()
          .hasRelationIn('link')
          .hasRelationOut('test')
        )
        q.find().then((nodes)->
          expect(nodes.length).to.equal(1)
          checkNodeInResult(nodes, 'a')
        )
      )

    it 'should not load secondary nodes in nested queries', ->
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
          expect(nodes[0].relation('link').all()[0].get('name')).to.be.undefined
        )
      )

    it 'should return all relations even on attribute selects', ->
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
          expect(nodes[0].relation('link').first()).to.be.defined
          expect(nodes[0].relation('link').all()).to.have.length.be(1)
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
          attrs = nodes[0].attributes()
          expect(attrs).to.have.property('name')
          expect(attrs).to.have.property('description')
          expect(attrs).to.not.have.property('skip')
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

  it 'should load in some secondary nodes with "selectIn"', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()

    a.relation('test').add(b)
    b.relation('link').add(c)
    a.set('name','alpha')

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link')
      .selectIn('test')
      .find().then((nodes)->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, b.id())
        expect(nodes[0].relationsIn['test'].nodes).to.have.length.be(1)
        expect(nodes[0].relationsIn['test'].nodes[0].id()).to.equal(a.id())
      )
    )

  it 'should ensure that nodes are not excluded based on the  "selectIn" flag', ->
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()
    d = new Weaver.Node()
    a.relation('test').add(b)
    b.relation('link1234').add(c)
    c.relation('link1234').add(d)

    a.save().then(->
      new Weaver.Query()
      .hasRelationOut('link1234')
      .selectIn('test')
      .find().then((nodes)->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, b.id())
        checkNodeInResult(nodes, c.id())
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
            expect(node.relation('link').all()['b1'].get('name')).to.equal('bravo-one')
          if node.id() is 'a2'
            expect(node.relation('link').all()['b2'].get('name')).to.equal(undefined)
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
              expect(node.relation('hasSpaceRequirement').all()['spaceReq1'].get('name')).to.equal('SpaceRequirementOne')
            when 'space2'
              expect(node.relationIn('to').nodes['spaceConn2'].relationIn('consistsOf').nodes['spaceGroup3'])
            when 'spaceGroup2'
              expect(node.relationOut('consistsOf').nodes['spaceGroup3'].relationOut('consistsOf').nodes['spaceConn1'])
      )
    )

  it 'should profile Weaver.Query', ->
    Weaver.Query.profile((queryResult) ->
      expect(queryResult.nodes[0].nodeId).to.equal('someNode')
    )

    node = new Weaver.Node('someNode')
    node.save().then(->
      Weaver.Node.load('someNode')
    )

  it 'should clear profilers', (done) ->
    wipeCurrentProject().then(->
      Weaver.Query.profile((queryResult) ->
        expect(queryResult.nodes[0].nodeId).to.equal('someNode')

        Weaver.Query.clearProfilers()
        done()
      )

      node = new Weaver.Node('someNode')
      node.save().then(->
        Weaver.Node.load('someNode')
      )
    ).then(->
      Weaver.Node.load('someNode')
    )
    return

  it.skip 'should know all timestamps and have them logically correct', (done) ->
    wipeCurrentProject().then(->
      Weaver.Query.profile((qr) ->
        total = qr.totalTime
        sum = qr.times.sdkToServer + qr.times.innerServerDelay + qr.times.serverToConn + qr.times.executionTime + qr.times.processingTime + qr.times.connToServer + qr.times.serverToSdk
        sum += qr.times.subQueryTime if qr.times.subQueryTime? # Sub query time is passed but never set

        Weaver.Query.clearProfilers()

        # Because of the posibility of skipping 1 ms between start and stop times
        # on operations we add an offset to the total value compared to the sum of timestamps
        expect(total).to.be.within(sum - 3, sum + 3)
        done()
      )

      node = new Weaver.Node('someNode')
      node.save().then(->
        Weaver.Node.load('someNode')
      )
    )
    return

  it 'should not know any of the timestamps in the response object itself', (done) ->
    wipeCurrentProject().then(->
      Weaver.Query.profile((qr) ->

        Weaver.Query.clearProfilers()

        expect(qr.sdkToServer).to.be.undefined
        expect(qr.innerServerDelay).to.be.undefined
        expect(qr.serverToConn).to.be.undefined
        expect(qr.executionTime).to.be.undefined
        expect(qr.subQueryTime).to.be.undefined
        expect(qr.processingTime).to.be.undefined
        expect(qr.connToServer).to.be.undefined
        expect(qr.serverToSdk).to.be.undefined

        done()
      )

      node = new Weaver.Node('someNode')
      node.save().then(->
        Weaver.Node.load('someNode')
      )
    )
    return

  it 'should be able to check existence on a list of Weaver nodes in their graphs', ->
    a = new Weaver.Node('a', 'graph');    b = new Weaver.Node('b', 'graph')
    c = new Weaver.Node('c', 'graph');    d = new Weaver.Node('d', 'other-graph')
    e = new Weaver.Node('e', 'graph');    f = new Weaver.Node('f', 'graph')
    g = new Weaver.Node('g', 'graph');    h = new Weaver.Node('h', 'graph')
    i = new Weaver.Node('i', 'graph');    j = new Weaver.Node('j')
    k = new Weaver.Node('k', 'graph');    l = new Weaver.Node('l')
    m = new Weaver.Node('m', 'graph');   a2 = new Weaver.Node('a', 'different-graph')
    b2 = new Weaver.Node('b');           c2 = new Weaver.Node('c', 'different-graph')
    myNodes = [a,b,c,m,d,e,f,g,h,i,j,k,l,a2,b2,c2]
    Weaver.Node.batchSave([a,b,m,d,g,j,k,l,a2,c2])
      .then( ->
        new Weaver.Query().findExistingNodes(myNodes).then((result)->
          trueNodes = [a,b,d,g,j,k,l,m,a2,c2]
          falseNodes = [c,e,f,h,i,b2]

          for t in trueNodes
            expect(result[t.getGraph()][t.id()]).to.be.true

          for f in falseNodes
            expect(result[f.getGraph()][f.id()]).to.be.false

          expect(Object.keys(result['different-graph']).length).to.equal(2)
          expect(Object.keys(result['graph']).length).to.equal(10)
          expect(Object.keys(result['undefined']).length).to.equal(3)
          expect(Object.keys(result['other-graph']).length).to.equal(1)
          expect(Object.keys(result).length).to.equal(4)
        )
      )

  it 'should not find attributes when checking existence on a list of nodes', ->
    n = new Weaver.Node('n')
    o = new Weaver.Node('o')
    n.set('name', 'Mathieu')
    myNodes = [n,o]
    Weaver.Node.batchSave([n,o])
      .then(->
        new Weaver.Query().findExistingNodes(myNodes).then((result) ->
          expect(result[n.getGraph()][n.id()]).to.be.true
          expect(result[o.getGraph()][o.id()]).to.be.true
          expect(Object.keys(result['undefined']).length).to.equal(2)
        )
      )

  it 'should not crash on weird characters when checking the existence of a node', ->
    p = new Weaver.Node("I'm annoying, do you know why?","my,annoying,graph")
    q = new Weaver.Node('q s',"graph,2")
    r = new Weaver.Node('Do,you,think,Im,annoying')
    myNodes = [p,q,r]
    Weaver.Node.batchSave([p,q,r])
      .then(->
        new Weaver.Query().findExistingNodes(myNodes).then((result) ->
          expect(result[p.getGraph()][p.id()]).to.be.true
          expect(result[q.getGraph()][q.id()]).to.be.true
          expect(result[r.getGraph()][r.id()]).to.be.true
          expect(Object.keys(result['my,annoying,graph']).length).to.equal(1)
          expect(Object.keys(result['graph,2']).length).to.equal(1)
          expect(Object.keys(result['undefined']).length).to.equal(1)
        )
      )

  # This test should only exist in a performance testing set
  it.skip 'should be able to check existence on a list of many Weaver nodes', ->
    myNodes = []
    savedNodes = []
    i = 0
    while i < 5000
      n = new Weaver.Node()
      myNodes.push(n)
      if i % 10 == 0
        savedNodes.push(n)
      i++
    Weaver.Node.batchSave(savedNodes)
    .then(->
      new Weaver.Query().findExistingNodes(myNodes).then((result)->
        countTrue = 0
        countTrue += 1 for key, value of result when value is true
        countFalse = 0
        countFalse += 1 for key, value of result when value is false
        expect(countTrue).to.equal(500)
        expect(countFalse).to.equal(4500)
        expect(Object.keys(result).length).to.equal(5000)
      )
    )

  describe 'simple nodes, with age', ->
    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    a.set('age', 4)
    b.set('age', 8)
    c.set('age', 12)
    a.set('name','Aaay')
    date = new Date().toISOString().slice(0, 19).replace('T', ' ')
    a.set('time', date)
    b.set('myboolean', false)
    c.set('greeting', "Hello")

    before ->
      wipeCurrentProject().then( ->
        Promise.all([a.save(), b.save(), c.save()])
      )

    it 'should do equalTo a wildcard', ->
      new Weaver.Query()
      .equalTo("name", '*')
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should do notEqualTo', ->
      new Weaver.Query()
      .notEqualTo("age", 8)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'c')
      )

    it 'should do greaterThan', ->
      new Weaver.Query()
      .greaterThan("age", 8)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'c')
      )

    it 'should do lessThan', ->
      new Weaver.Query()
      .lessThan("age", 8)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should do greaterThanOrEqualTo', ->
      new Weaver.Query()
      .greaterThanOrEqualTo("age", 8)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )

    it 'should do lessThanOrEqualTo', ->
      new Weaver.Query()
      .lessThanOrEqualTo("age", 8)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )

    it 'should be able to combine greaterThan and lessThan', ->
      new Weaver.Query()
      .lessThan("age", 12)
      .greaterThan("age", 4)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
      )

    it 'should be able to combine greaterThanOrEqualTo and lessThan', ->
      new Weaver.Query()
      .lessThanOrEqualTo("age", 12)
      .greaterThan("age", 4)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )

    it 'should be able to combine greaterThan and lessThanOrEqualTo', ->
      new Weaver.Query()
      .lessThan("age", 12)
      .greaterThanOrEqualTo("age", 4)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(2)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
      )

    it 'should be able to combine greaterThanOrEqualTo and lessThanOrEqualTo', ->
      new Weaver.Query()
      .lessThanOrEqualTo("age", 12)
      .greaterThanOrEqualTo("age", 4)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(3)
        checkNodeInResult(nodes, 'a')
        checkNodeInResult(nodes, 'b')
        checkNodeInResult(nodes, 'c')
      )

    it 'should be able to compare timestamps from attributes with current time', ->
      new Weaver.Query()
      .equalTo('time', date)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should be able to compare timestamps from attributes', ->
      new Weaver.Query()
      .notEqualTo('time', '2017-01-03 12:59:27')
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'a')
      )

    it 'should be able to compare Strings from attributes as lessThan', ->
      new Weaver.Query()
      .lessThan('greeting', "World")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'c')
      )

    it 'should be able to compare Strings from attributes as greaterThan', ->
      new Weaver.Query()
      .greaterThan('greeting', "World")
      .find().then((nodes) ->
        expect(nodes.length).to.equal(0)
      )

    it 'should be able to compare Booleans from attributes', ->
      new Weaver.Query()
      .notEqualTo('myboolean', true)
      .find().then((nodes) ->
        expect(nodes.length).to.equal(1)
        checkNodeInResult(nodes, 'b')
      )

  describe 'count behaviour', ->
    query = (withRelations = false, limit = false, sortOrder = undefined) ->
      q = new Weaver.Query()
      q.withRelations if withRelations
      q.limit(10) if limit
      q.order(['label'], sortOrder) if sortOrder?
      q.count()

    before ->
      nodes = []
      for i in [0..100]
        node = new Weaver.Node()
        node.set('label', i)
        nodes.push(node)

      wipeCurrentProject().then( ->
        Weaver.Node.batchSave(nodes)
      )

    it 'count should be correct', ->
      query().then((c) ->
        expect(c).to.equal(101)
      )

    it 'count with limit should be correct', ->
      query(false, true).then((c) ->
        expect(c).to.equal(101)
      )

    it 'ascendingLength should equal unorderedLength', ->
      query(false, true, true).then((c) ->
        expect(c).to.equal(101)
      )

    it 'descendingLength should equal ascendingLength', ->
      query(false, true, false).then((c) ->
        expect(c).to.equal(101)
      )

    it 'withRelations should not matter', ->
      query(true, true).then((c) ->
        expect(c).to.equal(101)
      )

    it 'ascendingLength withRelations should be correct', ->
      query(true, true, true).then((c) ->
        expect(c).to.equal(101)
      )

    it 'descendingLength withRelations should be correct', ->
      query(true, true, false).then((c) ->
        expect(c).to.equal(101)
      )

  describe 'query a lot of nodes', ->

    before ->
      wipeCurrentProject()

    it 'should find 100 nodes', ->
      Weaver.Node.batchSave((new Weaver.Node() for i in [0...100]))
      .then(->
        new Weaver.Query().find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(100)
        new Weaver.Query().unlimited(50)
      ).then((nodes) ->
        expect(nodes.length).to.equal(100)
        new Weaver.Query().unlimited(100)
      ).then((nodes) ->
        expect(nodes.length).to.equal(100)
        new Weaver.Query().unlimited(1500)
      ).then((nodes) ->
        expect(nodes.length).to.equal(100)
      )

    it 'should find 1000 nodes', ->
      Weaver.Node.batchSave((new Weaver.Node() for i in [0...900]))
      .then(->
        new Weaver.Query().find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1000)
        new Weaver.Query().unlimited(50)
      ).then((nodes) ->
        expect(nodes.length).to.equal(1000)
        new Weaver.Query().unlimited(100)
      ).then((nodes) ->
        expect(nodes.length).to.equal(1000)
        new Weaver.Query().unlimited(1500)
      ).then((nodes) ->
        expect(nodes.length).to.equal(1000)
      )

    it 'should find 1500 nodes', ->
      Weaver.Node.batchSave((new Weaver.Node() for i in [0...500]))
      .then(->
        new Weaver.Query().find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1000)
        new Weaver.Query().unlimited(50)
      ).then((nodes) ->
        expect(nodes.length).to.equal(1500)
        new Weaver.Query().unlimited(100)
      ).then((nodes) ->
        expect(nodes.length).to.equal(1500)
        new Weaver.Query().unlimited(1500)
      ).then((nodes) ->
        expect(nodes.length).to.equal(1500)
      )

    it 'should find 2500 nodes', ->
      Weaver.Node.batchSave((new Weaver.Node() for i in [0...1000]))
      .then(->
        new Weaver.Query().find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1000)
        new Weaver.Query().unlimited(50)
      ).then((nodes) ->
        expect(nodes.length).to.equal(2500)
        new Weaver.Query().unlimited(100)
      ).then((nodes) ->
        expect(nodes.length).to.equal(2500)
        new Weaver.Query().unlimited(1500)
      ).then((nodes) ->
        expect(nodes.length).to.equal(2500)
      )

  describe 'query nodes in one stream using a transaction', ->
    before ->
      wipeCurrentProject()
      .then(->
        Weaver.Node.batchSave((new Weaver.Node(i) for i in [0...5]))
      )

    it 'should find 5 nodes in steps of 1', ->
      query = null
      transaction = null
      Weaver.getInstance().startTransaction()
      .then((trx)->
        transaction = trx
        query = new Weaver.Query()
        .keepOpen()
        .batchSize(1)
        query.find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(0)
      ).finally(->
        transaction.commit()
      )

    it 'should find 5 nodes in steps of 2', ->
      query = null
      transaction = null
      Weaver.getInstance().startTransaction()
      .then((trx)->
        transaction = trx
        query = new Weaver.Query()
        .keepOpen()
        .batchSize(2)
        query.find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(2)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(2)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(0)
      ).finally(->
        transaction.commit()
      )

    it 'should find first three nodes in one step', ->
      query = null
      transaction = null
      Weaver.getInstance().startTransaction()
      .then((trx)->
        transaction = trx
        query = new Weaver.Query()
        .keepOpen()
        .batchSize(3)
        query.find()
      ).then((nodes) ->
        expect(nodes.length).to.equal(3)
        transaction.commit()
      ).then( ->
        query.next().should.be.rejectedWith("No held result set could be found for code")
      )

    it 'should use transaction implicitly', ->
      query = null
      transaction = null

      query = new Weaver.Query()
      .keepOpen()
      .batchSize(2)
      query.find()
      .then((nodes) ->
        transaction = Weaver.getCoreManager().currentTransaction
        expect(nodes.length).to.equal(2)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(2)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(1)
        query.next()
      ).then((nodes) ->
        expect(nodes.length).to.equal(0)
      ).finally(->
        query.close()
      )
