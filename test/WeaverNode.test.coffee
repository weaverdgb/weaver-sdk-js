require("./test-suite")()

cuid        = require('cuid')
Weaver      = require('./../src/Weaver')
WeaverError = require('./../../weaver-commons-js/src/WeaverError')

require('./../src/WeaverNode')  # This preloading will be an issue

describe 'WeaverNode test', ->

  before (done) ->
    Weaver.initialize(WEAVER_ADDRESS).then(->

      # 1. Authenticate
      # 2. Get list of projects
      # 3. Use that project with Weaver.useProject(project)

      wipe()
    ).then(->
      done();
    )
    return


  it 'should create a new node', (done) ->
    node = new Weaver.Node()

    node.save().then((node) ->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.id(), node.id())
      done()
    )
    return


  it 'should remove a node', (done) ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.destroy()
    ).then(->
      Weaver.Node.load(node.id())
    ).catch((error) ->
      assert.equal(error.code, WeaverError.NODE_NOT_FOUND)
      done()
    )
    return


  it 'should set a new string attribute', (done) ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('name', 'Foo')
      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), 'Foo')
      done()
    )
    return


  it 'should set a new boolean attribute', (done) ->
    node = new Weaver.Node()
    node.set('isBar', false)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('isBar'), false)
      done()
    )
    return


  it 'should set a new number attribute', (done) ->
    node = new Weaver.Node()
    node.set('length', 3)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('length'), 3)
      done()
    )
    return


  it 'should set a new number double attribute', (done) ->
    node = new Weaver.Node()
    node.set('halved', 1.5)

    node.save().then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('halved'), 1.5)
      done()
    )
    return


  it 'should unset an attribute', (done) ->
    node = new Weaver.Node()

    node.save().then((node) ->
      node.set('name', 'Foo')
      node.save()
    ).then(->
      node.unset('name')
      assert.equal(node.get('name'), undefined)
      node.save()
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), undefined)
      done()
    )
    return


  it 'should add a new relation', (done) ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    foo.relation('comesBefore').add(bar)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      assert.isDefined(loadedNode.relation('comesBefore').nodes[bar.id()])
      done()
    )
    return


  it 'should remove a relation', (done) ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()
    foo.relation('comesBefore').add(bar)

    foo.save().then(->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      loadedNode.relation('comesBefore').remove(bar)
      loadedNode.save()
    ).then( ->
      Weaver.Node.load(foo.id())
    ).then((loadedNode) ->
      relations = (k for k of loadedNode.relations)
      assert.lengthOf(relations, 0)
      done()
    )
    return


  it 'should set an existing attribute with new value', (done) ->
    node = new Weaver.Node()
    node.set('name', 'Foo')

    node.save().then((node) ->
      node.set('name', 'Bar')
      node.save()
    ).then(->
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      assert.equal(loadedNode.get('name'), 'Bar')
      done()
    )
    return


  it 'should give an error if node already exists', (done) ->
    node = new Weaver.Node('a')

    node.save().then().catch((error) ->
      assert.equal(error.code, WeaverError.NODE_ALREADY_EXISTS)
    )
    done()
    return


  it 'should give an error if node does not exists', (done) ->
    Weaver.Node.load(cuid()).then().catch((error) ->
      assert.equal(error.code, WeaverError.NODE_NOT_FOUND)
      done()
    )
    return