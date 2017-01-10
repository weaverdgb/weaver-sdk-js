require("./test-suite")()

# Weaver
Weaver      = require('./../src/Weaver')
WeaverError = require('./../../weaver-commons-js/src/WeaverError')
require('./../src/WeaverNode')  # This preloading will be an issue
require('./../src/WeaverUser')

describe 'Weaver User', ->
  this.timeout(2000)

  before (done) ->
    console.log WEAVER_ADDRESS
    Weaver.initialize(WEAVER_ADDRESS)
    .then(->
      wipe()
    ).then(->
      done();
    )
    return


  # it 'should signup users', (done) ->
  #   Weaver.User.signUp('asdf', 'zxcv')
  #   .then((user) =>
  #     assert(user.getSessionToken())
  #     done()
  #   )


  it 'should login users, receiving a valid jwt', ->
    user = new Weaver.User()
    user.logIn('phoenix','Schaap')
    .then((res) ->
      console.log res.token
      token = res.token
      token.should.be.a('string')
    )

    
  it 'should fails when trying to login with non existing user', ->
    user = new Weaver.User()
    user.logIn('andromeda','Chains')
    .then().catch((err) ->
      console.log err
    )
  
  
  it 'should returns jwt from the loggedin user', ->
    user = new Weaver.User()
    user.current('phoenix')
    .then((res) ->
      console.log res
      res.should.be.a('string')
    )
  
  
  it 'should return null when trying to get the jwt of a non loggedin user', ->
    user = new Weaver.User()
    user.current('andromeda')
    .then().catch((error) ->
      console.log error
      assert.isNull(error,'There is no andromeda user loggedin, that is fine')
    )

    
    # Weaver.User.signUp('asdf', 'zxcv')
    # .then(->
    #   Weaver.User.logIn('asdf', 'zxcv')
    # )
    # .then((user) ->
    #   assert.equal(user.get('username'), 'asdf');
    #   done()
    # )


  # it 'should fail signup with taken username', (done) ->
  #   Weaver.User.signUp('asdf', 'zxcv')
  #   .then(->
  #     Weaver.User.signUp('asdf', 'asdf3')
  #   ).then().catch((error) ->
  #     assert.equal(error.code, WeaverError.USERNAME_TAKEN)
  #     done()
  #   )
  #
  #
  # it 'should fail login with wrong username', (done) ->
  #   Weaver.User.signUp('asdf', 'zxcv')
  #   .then(->
  #     Weaver.User.logIn('false_user', 'asdf3')
  #   ).then().catch((error) ->
  #     assert.equal(error.code, WeaverError.USERNAME_NOT_FOUND)
  #     done()
  #   )
  #
  #
  # it 'should fail login with wrong password', (done) ->
  #   Weaver.User.signUp('asdf', 'zxcv')
  #   .then(->
  #     Weaver.User.logIn('asdf', 'asdfWrong')
  #   ).then().catch((error) ->
  #     assert.equal(error.code, WeaverError.PASSWORD_INCORRECT)
  #     done()
  #   )