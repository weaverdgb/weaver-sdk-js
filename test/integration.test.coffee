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


  it 'should get server version', ->
    version = Weaver.getCoreManager().getCommController().GET('application.version')
    version.should.eventually.be.a('string')


  it 'should create a new node', (done) ->
    node = new Weaver.Node()
    assert.isFalse(node.saved)

    node.save()
    .then((node) ->
      assert.isTrue(node.saved)

      # Reload
      Weaver.Node.get(node.id())
    ).then((loadedNode) ->
      done() # No errors so its good
    )


  it 'should give an error if node already exists', (done) ->
    node = new Weaver.Node('a')

    node.save().then().catch((error) ->
      assert.equal(error.code, WeaverError.NODE_ALREADY_EXISTS)
      done()
    )


  it 'should give an error if node does not exists', (done) ->
    node = new Weaver.Node('b')

    node.save().then().catch((error) ->
      assert.equal(error.code, WeaverError.NODE_NOT_FOUND)
      done()
    )











