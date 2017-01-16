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
    Weaver.User.logIn('phoenix','phoenix')
    .then((res) ->
      token = res.token
      token.should.be.a('string')
    )
  
  it 'should give the user permission', ->
    weaverUser = new Weaver.User()
    weaverUser.permission('phoenix').then((res) ->
      expect(res).to.equal('[read_user, create_user, delete_user, create_role, read_role, delete_role, create_permission, read_permission, delete_permission, read_application, create_application, delete_application, create_directory, read_directory, delete_directory]')
    )
  
  it 'should fails when trying to login with non existing user', ->
    Weaver.User.logIn('andromeda','Chains')
    .then().catch((err)->
      assert.equal(err.code, WeaverError.USERNAME_NOT_FOUND)
    )
  
  it 'should returns jwt from the loggedin user', ->
    weaverUser = new Weaver.User()
    weaverUser.current('phoenix').should.eventually.be.a('string')
  
  
  it 'should performs logOut action for the current user without specifying the user', ->
    weaverUser = new Weaver.User()
    weaverUser.logOut()
    .then( ->
    )
  
  
  it 'should return null when trying to get the jwt of a non loggedin user', ->
    weaverUser = new Weaver.User()
    weaverUser.current('andromeda')
    .then().catch((error) ->
      assert.isNull(error,'There is no andromeda user loggedin, that is fine')
    )
  
  it 'should signUp a user', ->
    weaverUser = new Weaver.User()
    Weaver.User.logIn('phoenix','phoenix')
    .then(->
      Weaver.User.signUp('phoenix','centaurus','centaurus@univer.se','centaurus','SYSUNITE')
    ).then(->
      weaverUser.logOut()
    ).then(->
      Weaver.User.logIn('centaurus','centaurus')
    ).then((res) ->
      res.token.should.be.a('string')
    )
  
  it 'should signOff a user and must fails if tries to logIn with the signedOff user', ->
    weaverUser = new Weaver.User()
    weaverUser.current('centaurus').then(->
      weaverUser.logOut()
    ).then(->
      Weaver.User.logIn('phoenix','phoenix')
    ).then(->
      weaverUser.current('phoenix')
    ).then(->
      weaverUser.signOff('phoenix','centaurus')
    ).then(->
      Weaver.User.logIn('centaurus','centaurus')
    ).then().catch((error) ->
      assert.equal(error.code, WeaverError.USERNAME_NOT_FOUND)
    )
  
  it 'should performs logOut action for the current user specifying the user', (done) ->
    weaverUser = new Weaver.User()
    Weaver.User.logIn('phoenix','phoenix')
    .then((res, err) ->
      if (!err)
        weaverUser.logOut('phoenix')
        .then((res, err) ->
          if (!err)
            done()
        )
    )
    return
  
  it 'should fails trying logOut action for the current user, bacause there is no current user loggedin', ->
    weaverUser = new Weaver.User()
    weaverUser.logOut()
    .then().catch((err) ->
      assert.equal(err.code, WeaverError.USERNAME_NOT_FOUND)
    )
  
  
  it 'should fails trying logOut action specifying non loggedin user', ->
    weaverUser = new Weaver.User()
    weaverUser.logOut('andromeda')
    .then().catch((err) ->
      assert.equal(err.code, WeaverError.USERNAME_NOT_FOUND)
    )
  
  it 'should fails trying to signUp with an existing userName', ->
      Weaver.User.logIn('phoenix','phoenix')
      .then(->
        Weaver.User.signUp('phoenix','andromeda','andromeda@univer.se','andromedas','SYSUNITE')
      ).then(->
        Weaver.User.signUp('phoenix','andromeda','centaurus@univer.se','andromedas','SYSUNITE')
      ).then(->
        assert(false)
      ).catch((error)->
        assert.equal(error.code, WeaverError.DUPLICATE_VALUE)
      )
  
  it 'should fails trying to signUp with an existing userEmail', ->
      Weaver.User.signUp('phoenix','andromedas','andromedas@univer.se','andromedas','SYSUNITE')
      .then(->
        Weaver.User.signUp('phoenix','andro','andromedas@univer.se','andromedas','SYSUNITE')
      ).then(->
        assert(false)
      ).catch((error)->
        assert.equal(error.code, WeaverError.DUPLICATE_VALUE)
      )