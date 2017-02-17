require("./test-suite")

describe 'WeaverUser Test', ->


  it 'should sign up a user', (done) ->
    username = cuid()
    user = new Weaver.User(username, "centaurus123", "centaurus@univer.se")

    assert.isTrue(not user.authToken?)
    Weaver.signOut().then(->
      user.signUp()
    ).then(->

      assert.equal(user.id(), Weaver.currentUser().id())
      assert.isTrue(user.authToken?)

      # Sign out and signin again
      Weaver.signOut()
    ).then(->
      expect(Weaver.currentUser()).to.be.undefined

      # Sign in
      Weaver.signIn(username, 'centaurus123')
    ).then((loadedUser) ->

      assert.equal(loadedUser.id(), Weaver.currentUser().id())

      # Assert email and username are set, while password is not set
      assert.equal(loadedUser.username, username)
      assert.equal(loadedUser.email, "centaurus@univer.se")
      assert.isTrue(not loadedUser.password?)
      done()
    )
    return


  it 'should sign out a user', (done) ->
    Weaver.signOut().then( ->
      # Writing is now not permitted
      node = new Weaver.Node()
      node.save()
    ).catch((error) ->
      # TODO: Assert error code
      done()
    )
    return


  it 'should sign in the session if token is saved', ->
    # TODO: Perhaps localforage is better for this instead of loki
    return

  it 'should create a user without signing in', ->
    return

  it 'should fail to login with incorrect username', (done) ->
    username = cuid()
    password = cuid()
    user     = new Weaver.User(username, password, "centaurus@univer.se")

    Weaver.signOut().then(->
      user.signUp()
    ).then(->
      Weaver.signOut()
    ).then(->
      # Sign in
      Weaver.signIn('username', password)
    ).catch((err) ->
      # TODO: Assert error code
      # assert.equal(err.code, Weaver.Error.USERNAME_NOT_FOUND)

      done()
    )
    return

  it 'should fail to login with incorrect password', (done) ->
    username = cuid()
    password = cuid()
    user     = new Weaver.User(username, password, "centaurus@univer.se")

    Weaver.signOut().then(->
      user.signUp()
    ).then(->
      Weaver.signOut()
    ).then(->
      # Sign in
      Weaver.signIn(username, 'password')
    ).catch((err) ->
      # TODO: Assert error code
      done()
    )
    return


  it 'should fail to login with non existing user', (done) ->
    Weaver.signOut().then(->
      # Sign in
      Weaver.signIn('username', 'password')
    ).catch((err) ->
      # TODO: Assert error code
      done()
    )
    return




  # Now time for Project access!! That means -> Project Service



  return

  # TODO: Fix this on server
  it 'should destroy a user', (done) ->
    username = cuid()
    password = cuid()
    user     = new Weaver.User(username, password, "centaurus@univer.se")

    # TODO: Change all these codes into creating a user without signing up
    Weaver.signOut().then(->
      user.signUp()
    ).then(->
      user.destroy()
    ).then(->
      # Sign in
      Weaver.signIn(username, password)
    ).catch((err) ->
      # TODO: Assert error code
      # assert.equal(err.code, Weaver.Error.USERNAME_NOT_FOUND)
      console.log err
      done()
    )
    return







  it 'should fail sign out if no user is signed in', ->
    weaverUser = new Weaver.User()
    weaverUser.logOut()
    .then().catch((err) ->
      assert.equal(err.code, Weaver.Error.USERNAME_NOT_FOUND)
    )


  it 'should fail signing up with an existing username', ->
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

  it 'should fail signing up with an existing email', ->
    Weaver.User.signUp('phoenix','andromedas','andromedas@univer.se','andromedas','SYSUNITE')
    .then(->
      Weaver.User.signUp('phoenix','andro','andromedas@univer.se','andromedas','SYSUNITE')
    ).then(->
      assert(false)
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.DUPLICATE_VALUE)
    )

  it 'should retrieve the list of all users', ->
    Weaver.User.list('phoenix','SYSUNITE')
    .then((res) ->
      res.should.contain({ userName: 'phoenix',userEmail: 'PLACEHOLDER@PLACE.HOLDER'})
    )

  it 'should fail retrieving the list with users when the user is not signed in', ->
    Weaver.User.list('andromeda','SYSUNITE')
    .then((res) ->
      assert(false)
    ).catch((error) ->
      assert.equal(error.code, Weaver.Error.SESSION_MISSING)
    )

  it 'should also set other fields', ->
    return
    # Other fields are also possible
    #user.set("phone", "+31637562188");
