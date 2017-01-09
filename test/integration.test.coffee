require("./test-suite")()

# Weaver
Weaver      = require('./../src/Weaver')
WeaverError = require('./../../weaver-commons-js/src/WeaverError')
require('./../src/WeaverNode')  # This preloading will be an issue

describe 'WeaverSDK Integration test', ->

  before (done) ->
    Weaver.initialize(WEAVER_ADDRESS).then(->

      # 1. Authenticate
      # 2. Get list of projects
      # 3. Use that project

      # Weaver.useProject(project)

      wipe()
    ).then(->
      done();
    )
    return


  it 'should', (done) ->

  it 'should', (done) ->

  it 'should', (done) ->

  it 'should', (done) ->

  it 'should', (done) ->

  it 'should', (done) ->

  it 'should', (done) ->

  it 'should', (done) ->

  it 'should', (done) ->

  it 'should', (done) ->


  it 'should get the weaver-server version', ->
    version = Weaver.getCoreManager().getCommController().GET('application.version')
    version.should.eventually.be.a('string')


  it 'should create a new node', (done) ->
    node = new Weaver.Node()
    assert.isFalse(node.saved)

    node.save()
    .then((node) ->
      assert.isTrue(node.saved)

      # Reload
      Weaver.Node.load(node.id())
    ).then((loadedNode) ->
      console.log(loadedNode)
      done() # No errors so its good
    )
    return


  it 'should remove a node', (done) ->
    return



  it 'should add a new relation', (done) ->
    foo = new Weaver.Node()
    bar = new Weaver.Node()

    # Set always means
    foo.relation('comes_before', bar)

    foo.save().then((foo) ->
      # Reload
      Weaver.Node.get(foo.id())
    ).then((loadedFoo) ->

      # assert has relation

      done() # No errors so its good
    )
    return


  it 'should give an error when removing an non-existing node', (done) ->
    return


  it 'should set a new attribute', (done) ->
    return


  it 'should set an existing attribute with new value', (done) ->
    return


  it 'should unset an attribute', (done) ->
    return


  it 'should give an error when unsetting a non-existing', (done) ->
    return




  it 'should give an error if node already exists', (done) ->
    node = new Weaver.Node('a')

    node.save().then().catch((error) ->
      assert.equal(error.code, WeaverError.NODE_ALREADY_EXISTS)
      done()
    )
    return


  it 'should give an error if node does not exists', (done) ->
    node = new Weaver.Node('b')

    node.save().then().catch((error) ->
      assert.equal(error.code, WeaverError.NODE_NOT_FOUND)
      done()
    )
    return











