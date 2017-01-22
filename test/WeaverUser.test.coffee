require("./test-suite")()

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

  it 'should login users, receiving a valid jwt', ->
    Weaver.User.logIn('phoenix','phoenix')
    .then((res) ->
      token = res.token
      token.should.be.a('string')
    )

  it 'should fails login users, with incorrect username', ->
    Weaver.User.logIn('phoenixs','phoenix')
    .then(->
      assert(false)
    ).catch((err)->
      assert.equal(err.code, Weaver.Error.USERNAME_NOT_FOUND)
    )

  it 'should fails login users, with incorrect password', ->
    Weaver.User.logIn('phoenix','phoenixs')
    .then(->
      assert(false)
    ).catch((err)->
      assert.equal(err.code, Weaver.Error.PASSWORD_INCORRECT)
    )

  it 'should give the user permission', ->
    weaverUser = new Weaver.User()
    weaverUser.permission('phoenix').then((res) ->
      expect(res).to.eql(['read_user', 'create_user', 'delete_user', 'create_role', 'read_role', 'delete_role', 'create_permission', 'read_permission', 'delete_permission', 'read_application', 'create_application', 'delete_application', 'create_directory', 'read_directory', 'delete_directory'])
    )

  it 'should fails when trying to login with non existing user', ->
    Weaver.User.logIn('foo','bar')
    .then().catch((err)->
      assert.equal(err.code, Weaver.Error.USERNAME_NOT_FOUND)
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
      assert.equal(error.code, Weaver.Error.SESSION_MISSING)
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
      Weaver.User.signOff('phoenix','centaurus')
    ).then(->
      Weaver.User.logIn('centaurus','centaurus')
    ).then().catch((error) ->
      assert.equal(error.code, Weaver.Error.USERNAME_NOT_FOUND)
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
      assert.equal(err.code, Weaver.Error.USERNAME_NOT_FOUND)
    )

  it 'should fails trying logOut action specifying non loggedin user', ->
    weaverUser = new Weaver.User()
    weaverUser.logOut('andromeda')
    .then().catch((err) ->
      assert.equal(err.code, Weaver.Error.USERNAME_NOT_FOUND)
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
      assert.equal(error.code, Weaver.Error.DUPLICATE_VALUE)
    )

  it 'should fails trying to signUp with an existing userEmail', ->
    Weaver.User.signUp('phoenix','andromedas','andromedas@univer.se','andromedas','SYSUNITE')
    .then(->
      Weaver.User.signUp('phoenix','andro','andromedas@univer.se','andromedas','SYSUNITE')
    ).then(->
      assert(false)
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.DUPLICATE_VALUE)
    )

  it 'should retrieve the list with users', ->
    Weaver.User.list('phoenix','SYSUNITE')
    .then((res) ->
      res.should.contain({ userName: 'phoenix',userEmail: 'PLACEHOLDER@PLACE.HOLDER'})
    )

  it 'should fails trying to retrieve the list with users when the user is not loggedin', ->
    Weaver.User.list('andromeda','SYSUNITE')
    .then((res) ->
      assert(false)
    ).catch((error) ->
      assert.equal(error.code, Weaver.Error.SESSION_MISSING)
    )

  it 'should fails trying to retrieve the list with users when the directory does not exits', ->
    Weaver.User.list('phoenix','SYS')
    .then((res) ->
      assert(false)
    ).catch((error) ->
      assert.equal(error.code, Weaver.Error.OTHER_CAUSE)
    )
