require("./test-suite")()

# Weaver
Weaver      = require('./../src/Weaver')
WeaverError = require('./../../weaver-commons-js/src/WeaverError')
require('./../src/WeaverNode')  # This preloading will be an issue

describe 'Weaver User', ->

  before (done) ->
    Weaver.initialize(WEAVER_ADDRESS)
    .then(->
      wipe()
    ).then(->
      done();
    )
    return


  it 'should signup users', (done) ->
    Weaver.User.signUp('asdf', 'zxcv')
    .then((user) =>
      assert(user.getSessionToken())
      done()
    )


  it 'should login users', (done) ->
    Weaver.User.signUp('asdf', 'zxcv')
    .then(->
      Weaver.User.logIn('asdf', 'zxcv')
    )
    .then((user) ->
      assert.equal(user.get('username'), 'asdf');
      done()
    )


  it 'should fail signup with taken username', (done) ->
    Weaver.User.signUp('asdf', 'zxcv')
    .then(->
      Weaver.User.signUp('asdf', 'asdf3')
    ).then().catch((error) ->
      assert.equal(error.code, WeaverError.USERNAME_TAKEN)
      done()
    )


  it 'should fail login with wrong username', (done) ->
    Weaver.User.signUp('asdf', 'zxcv')
    .then(->
      Weaver.User.logIn('false_user', 'asdf3')
    ).then().catch((error) ->
      assert.equal(error.code, WeaverError.USERNAME_NOT_FOUND)
      done()
    )


  it 'should fail login with wrong password', (done) ->
    Weaver.User.signUp('asdf', 'zxcv')
    .then(->
      Weaver.User.logIn('asdf', 'asdfWrong')
    ).then().catch((error) ->
      assert.equal(error.code, WeaverError.PASSWORD_INCORRECT)
      done()
    )