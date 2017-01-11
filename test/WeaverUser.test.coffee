require("./test-suite")()

# Weaver
Weaver      = require('./../src/Weaver')
WeaverError = require('./../../weaver-commons-js/src/WeaverError')
require('./../src/WeaverNode')  # This preloading will be an issue
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

  it 'should login users, receiving a valid jwt', ->
    user = new Weaver.User()
    user.logIn('phoenix','phoenix')
    .then((res) ->
      token = res.token
      token.should.be.a('string')
    ).catch((err) ->
    )
    
  it 'should fails when trying to login with non existing user', ->
    user = new Weaver.User()
    user.logIn('andromeda','Chains')
    .then().catch((err) ->
      done()
    )
  
  
  it 'should returns jwt from the loggedin user', ->
    user = new Weaver.User()
    user.current('phoenix')
    .then((res) ->
      res.should.be.a('string')
    )
    
  it 'should performs logOut action for the current user without specifying the user', ->
    user = new Weaver.User()
    user.logOut()
    .then((res) ->
    )
  
  
  it 'should return null when trying to get the jwt of a non loggedin user', ->
    user = new Weaver.User()
    user.current('andromeda')
    .then().catch((error) ->
      assert.isNull(error,'There is no andromeda user loggedin, that is fine')
    )
    
  it 'should signUp a user', ->
    user = new Weaver.User()
    user.logIn('phoenix','phoenix')
    .then((res) ->
      user.signUp('phoenix','centaurus','centaurus@univer.se','centaurus','SYSUNITE')
      .then((res) ->
        user.logOut()
        .then((res) ->
          user.logIn('centaurus','centaurus')
          .then((res, err) ->
            res.token.should.be.a('string')
          )
        )
      )
    )
    
  it 'should signOff a user', ->
    user = new Weaver.User()
    user.current('centaurus').then((res) ->
      user.logOut().then((res) ->
        user.logIn('phoenix','phoenix').then((res) ->
          user.current('phoenix').then((res) ->
            user.signOff('phoenix','centaurus').then((res) ->
              user.logIn('centaurus','centaurus').then((res) ->
                
              )
            )
          )
        )
      )
    )
      
  it 'should performs logOut action for the current user specifying the user', (done) ->
    user = new Weaver.User()
    user.logIn('phoenix','phoenix')
    .then((res, err) ->
      if (!err)
        user.logOut('phoenix')
        .then((res, err) ->
          if (!err)
            done()
        )
    )
    return
    
  it 'should fails trying logOut action for the current user, bacause there is no current user loggedin', ->
    user = new Weaver.User()
    user.logOut()
    .then().catch((err) ->
      done()
    )
    
    
  it 'should fails trying logOut action specifying non loggedin user', ->
    user = new Weaver.User()
    user.logOut('andromeda')
    .then().catch((err) ->
      done()
    )