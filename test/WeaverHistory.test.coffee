weaver  = require("./test-suite").weaver
wipeCurrentProject  = require("./test-suite").wipeCurrentProject
Weaver  = require('../src/Weaver')
Promise = require('bluebird')

describe 'WeaverHistory test', ->
  beforeEach ->
    wipeCurrentProject()

  it 'should set a new string attribute', ->
    node = new Weaver.Node()
    nodeB = new Weaver.Node()

    node.save().then((node) ->
      node.set('name', 'Foo')
      node.save()
    ).then(->
      node.set('name', 'Bar')
      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), 'Bar')
      history = new Weaver.History()
      history.getHistory(node)
    ).then((response) ->
      expect(response).to.have.length.be(3)
      nodeB.save()
    ).then(->
      history = new Weaver.History()
      h = history.getHistory([node, nodeB])
    ).then((response) ->
      expect(response).to.have.length.be(4)
      history = new Weaver.History()
      history.forUser('admin')
      history.fromDateTime('2017-03-23 12:38')
      history.beforeDateTime('2018-03-23 12:39')
      history.getHistory(node, 'name')
    )

  it 'should get history for a Weaver Node or for the id', ->
    node = new Weaver.Node()
    history = new Weaver.History()
    node.save()
    .then((node) ->
      history.getHistory(node)
    ).then((response) ->
      expect(response).to.have.length.be(1)
      history.getHistory(node.id())
    ).then((response) ->
      expect(response).to.have.length.be(1)
    )

  it 'should get history for an Array of Weaver Nodes or for those ids', ->
    nodeA = new Weaver.Node()
    nodeB = new Weaver.Node()
    nodeC = new Weaver.Node()
    history = new Weaver.History()

    promises = []
    promises.push(nodeA.save())
    promises.push(nodeB.save())
    promises.push(nodeC.save())

    Promise.all(promises)
    .then((nodes) ->
      history.getHistory(nodes)
    ).then((response) ->
      expect(response).to.have.length.be(3)
      nodes = [nodeA.id(),nodeB.id(),nodeC.id()]
      history.getHistory(nodes)
    ).then((res) ->
      expect(res).to.have.length.be(3)
    )

  it 'should retrieve history for a key-value', ->

    history = new Weaver.History()
    node = new Weaver.Node()

    node.save()
    .then((node) ->
      node.set('name', 'Chikuku')
      node.set('surname', 'Kulubaluka')
      node.save()
    ).then((node) ->
      node.set('name','Chikuku king of Tormerkia')
      node.save()
    ).then((node) ->
      history.getHistory(node,'name')
    ).then((res) ->
      expect(res).to.have.length.be(2)
      assert.equal(res[0].key,'name')
      assert.equal(res[0].value,'Chikuku')
      assert.equal(res[0].action,'create-attribute')
      assert.equal(res[1].key,'name')
      assert.equal(res[1].value,'Chikuku king of Tormerkia')
      assert.equal(res[1].action,'update-attribute')
    )


  it 'should retrieve history for a relation', ->
    history = new Weaver.History()

    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()

    a.set('name', 'Foo')
    b.set('name', 'Bar')
    c.set('name', 'Pub')

    a.relation('is').add(b)

    Weaver.Node.batchSave([a,b,c])
    .then(->
      a.relation('is').update(b,c)
      a.save()
    ).then((node) ->
      history.getHistory(null, null, node.id(),null)
    ).then((res) ->
      expect(res).to.have.length.be(2)
      assert.equal(res[0].action,'create-relation')
      assert.equal(res[0].key,'is')
      assert.equal(res[0].from,a.id())
      assert.equal(res[0].to,b.id())
      assert.equal(res[1].action,'update-relation')
      assert.equal(res[1].key,'is')
      assert.equal(res[1].to,c.id())
    )


  it 'should limit history', ->
    Promise.all((new Weaver.Node()).save() for i in [0..30]).then( ->
      history = new Weaver.History()
      history.limit(20)
      history.dumpHistory()
      .then((response) ->
        expect(response).to.have.length.be(20)
      )
    )

  it 'should retrieve 2 lines of history for the user admin', ->
    Promise.all((new Weaver.Node()).save() for i in [0..1]).then(->
      history = new Weaver.History()
      history.limit(2)
      history.forUser('admin')
      history.dumpHistory()
      .then((response) ->
        assert.equal(response.length,2)
        for row in response
          assert.equal(row.user,'root')
      )
    )

  it.skip 'should not allow sql injection in queries', ->
    new Weaver.Node().save().then(->
      new Weaver.Node().save()
    ).then(->
      history = new Weaver.History()
      history.limit('10; TRUNCATE TABLE `trackerdb`; --')
      history.dumpHistory()
    ).then(->
      new Weaver.Node().save()
    ).then(->
      history = new Weaver.History()
      history.limit(10)
      history.dumpHistory()
    ).should.eventually.have.length.be(3)

  it 'should not allow sql injection queries', ->
    new Weaver.Node("'; TRUNCATE TABLE `trackerdb`; --").save().then(->
      history = new Weaver.History()
      history.dumpHistory()
    ).should.eventually.have.length.be(1)

  it 'should reject public access to history', ->
    weaver.signOut().then(->
      new Weaver.History().dumpHistory()
    ).should.be.rejected

  it 'should reject users without project access from accessing history', ->
    weaver.currentProject().destroy().then(->
      new Weaver.Project('history test').create()
    ).then((p)->
      weaver.useProject(p)
      new Weaver.User('testuser', 'testpassword', 'test@example.com').signUp()
    ).then(->
      new Weaver.History().dumpHistory()
    ).should.be.rejectedWith(/Permission denied/)


  it 'should retrieve 20 rows of history in ascendent mode, default order', ->
    Promise.all((new Weaver.Node()).save() for i in [0..30]).then( ->
      history = new Weaver.History()
      history.limit(20)
      history.getHistory()
      .then((response) ->
        expect(response).to.have.length.be(20)
        assert.equal(response[0].seqnr,1)
        assert.equal(response[19].seqnr,20)
      )
    )

  it.skip 'should retrieve 20 rows of history in descent mode', ->
    Promise.all((new Weaver.Node()).save() for i in [0..30]).then( ->
      history = new Weaver.History()
      history.limit(20)
      history.sorted('descending')
      history.getHistory()
      .then((response) ->
        expect(response).to.have.length.be(20)
        assert.equal(response[0].seqnr,31)
        assert.equal(response[19].seqnr,12)
      )
    )

  it.skip 'should retrieve 1st page with 10 results in default order', ->
    Promise.all((new Weaver.Node()).save() for i in [0..30]).then( ->
      history = new Weaver.History()
      history.limit(10)
      history.offset(0)
      history.getHistory()
      .then((response) ->
        expect(response).to.have.length.be(10)
        assert.equal(response[0].seqnr,1)
        assert.equal(response[9].seqnr,10)
      )
    )

  it.skip 'should retrieve 1st page with 10 results in descending order', ->
    Promise.all((new Weaver.Node()).save() for i in [0..30]).then( ->
      history = new Weaver.History()
      history.sorted('descending')
      history.limit(10)
      history.offset(0)
      history.getHistory()
      .then((response) ->
        expect(response).to.have.length.be(10)
        assert.equal(response[0].seqnr,31)
        assert.equal(response[9].seqnr,22)
      )
    )

  it.skip 'should retrieve 2nd page with 10 results in default order', ->
    Promise.all((new Weaver.Node()).save() for i in [0..30]).then( ->
      history = new Weaver.History()
      history.limit(10)
      history.offset(10)
      history.getHistory()
      .then((response) ->
        expect(response).to.have.length.be(10)
        assert.equal(response[0].seqnr,11)
        assert.equal(response[9].seqnr,20)
      )
    )

  it.skip 'should retrieve 2nd page with 10 results in descending order', ->
    Promise.all((new Weaver.Node()).save() for i in [0..30]).then( ->
      history = new Weaver.History()
      history.sorted('descending')
      history.limit(10)
      history.offset(10)
      history.getHistory()
      .then((response) ->
        expect(response).to.have.length.be(10)
        assert.equal(response[0].seqnr,21)
        assert.equal(response[9].seqnr,12)
      )
    )
