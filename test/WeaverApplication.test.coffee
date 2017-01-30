require("./test-suite")()

# Weaver
Weaver = require('./../src/Weaver')

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


  it 'should fails on creates an application when the user is not correct', ->
    weaverApplication = new Weaver.Application()
    Weaver.User.logIn('phoenix','phoenix')
    .then( ->
      weaverApplication.createApplication('steve','fooApplication1','barProject1')
    ).then( ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code, Weaver.Error.SESSION_MISSING)
    )

  it 'should fails on creates an application when the data is missing some attribute', ->
    weaverApplication = new Weaver.Application()
    Weaver.User.logIn('phoenix','phoenix')
    .then( ->
      weaverApplication.createApplication('phoenix','barProject1')
    ).then( ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.DATATYPE_INVALID)
    )
