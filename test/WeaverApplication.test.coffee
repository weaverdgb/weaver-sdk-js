require("./test-suite")()

# Weaver
Weaver      = require('./../src/Weaver')
WeaverError = require('./../../weaver-commons-js/src/WeaverError')
require('./../src/WeaverNode')  # This preloading will be an issue
require('./../src/WeaverApplication')
require('./../src/WeaverUser')

describe 'Weaver User', ->
  this.timeout(2000)

  before (done) ->
    Weaver.initialize(WEAVER_ADDRESS)
    .then(->
      wipe()
    ).then(->
      done();
    )
    return

  it 'should creates an application', ->
    weaverApplication = new Weaver.Application()
    Weaver.User.logIn('phoenix','phoenix')
    .then( ->
      weaverApplication.createApplication('phoenix','fooApplication1','barProject1')
    ).then((res) ->
      assert.equal(res.success,'Document created')
    )
    

  it 'should fails on creates an application', ->
    weaverApplication = new Weaver.Application()
    Weaver.User.logIn('phoenix','phoenix')
    .then( ->
      weaverApplication.createApplication('steve','fooApplication1','barProject1')
    ).then( ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code, WeaverError.SESSION_MISSING)
    )
    
  it 'should fails on creates an application when userName is not there', ->
    weaverApplication = new Weaver.Application()
    Weaver.User.logIn('phoenix','phoenix')
    .then( ->
      weaverApplication.createApplication('phoenix','barProject1')
    ).then( ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,WeaverError.DATATYPE_INVALID)
    )
    