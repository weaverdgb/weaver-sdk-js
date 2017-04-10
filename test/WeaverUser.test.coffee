require("./test-suite")

describe 'WeaverUser Test', ->

  it 'should sign up a user', (done) ->
    username = cuid()
    user = new Weaver.User(username, "centaurus123", "centaurus@univer.se")
    assert.isTrue(not user.authToken?)
    weaver.signOut().then(->
      user.signUp()
    ).then(->

      assert.equal(user.id(), weaver.currentUser().id())
      assert.isTrue(user.authToken?)

      # Sign out and sign in again
      weaver.signOut()
    ).then(->
      expect(weaver.currentUser()).to.be.undefined

      # Sign in
      weaver.signInWithUsername(username, 'centaurus123')
    ).then((loadedUser) ->

      assert.equal(loadedUser.id(), weaver.currentUser().id())

      # Assert email and username are set, while password is not set
      assert.equal(loadedUser.username, username)
      assert.equal(loadedUser.email, "centaurus@univer.se")
      assert.isTrue(not loadedUser.password?)
      done()
    )
    return

  it 'should sign in an admin using a token', ->
    authToken = null;
    # Sign in to obtain a token
    weaver.signInWithUsername('admin', 'admin').then((user) ->
      authToken = user.authToken
      # Sign out again
      weaver.signOut()
    ).then( ->
      # Try to sign in with obtained token
      weaver.signInWithToken(authToken)
    ).then((user) ->
      # Verify logged in user
      assert.equal('admin', user.username)
      assert.isTrue(user.authToken?)
    )

  it 'should sign in a user using a token', ->
    authToken = null;
    username = cuid()
    user = new Weaver.User(username, "centaurus123", "centaurus@univer.se")
    # Assert that user has no authToken
    assert.isTrue(not user.authToken?)
    if(weaver.currentUser())
      weaver.signOut().then( ->
        # Sign up a new user and obtain a token
        user.signUp()
      ).then(->
        authToken = user.authToken
        # Sign out again
        weaver.signOut()
      ).then( ->
        # Try to sign in with obtained token
        weaver.signInWithToken(authToken)
      ).then((user) ->
        # Verify logged in user
        assert.equal(username, user.username)
        assert.isTrue(user.authToken?)
      )



  it 'should sign out a user', (done) ->
    weaver.signOut().then( ->
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

    weaver.signOut().then(->
      user.signUp()
    ).then(->
      weaver.signOut()
    ).then(->
      # Sign in
      weaver.signInWithUsername('username', password)
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

    weaver.signOut().then(->
      user.signUp()
    ).then(->
      weaver.signOut()
    ).then(->
      # Sign in
      weaver.signInWithUsername(username, 'password')
    ).catch((err) ->
      # TODO: Assert error code
      done()
    )
    return

  it 'should fail to login with non valid token', (done) ->
    weaver.signOut().then(->
      weaver.signInWithToken('some invalid token')
    ).then((user) ->
      assert(false)
    ).catch((err) ->
      done()
    )
    return

  it 'should fail to login with non existing user', (done) ->
    weaver.signOut().then(->
      # Sign in
      weaver.signInWithUsername('username', 'password')
    ).catch((err) ->
      # TODO: Assert error code
      done()
    )
    return


  it.skip 'should create the admin user upon initialization', (done) ->

  it.skip 'should create the admin role upon initialization', (done) ->

  it.skip 'should allow only the admin to wipe a project', (done) ->

  it.skip 'should create a new project by default on private ACL', (done) ->

  it.skip 'should deny other users from reading project nodes on private ACL', (done) ->

  it.skip 'should deny other users from writing project nodes on private ACL', (done) ->

  it.skip 'should allow other users from reading project nodes on public ACL', (done) ->

  it.skip 'should allow other users from writing project nodes on public ACL', (done) ->

  it.skip 'should allow other users from reading project nodes on role ACL ', (done) ->

  it.skip 'should allow other users from writing project nodes on role ACL ', (done) ->

  it.skip 'should allow other users from reading project nodes on child role ACL ', (done) ->

  it.skip 'should allow other users from writing project nodes on child role ACL ', (done) ->

  it.skip 'should restrict read access when getting nodes', (done) ->

  it.skip 'should restrict read access when querying nodes', (done) ->

  it.skip 'should restrict write access when writing nodes', (done) ->


  it 'should fail signing up with an existing username', (done) ->
    username = cuid()
    password = cuid()
    user     = new Weaver.User(username, password, "centaurus@univer.se")

    weaver.signOut().then(->
      user.signUp()
    ).then(->
      weaver.signOut()
    ).then(->
      adminSignin()
    ).then(->
      sameUsernameUser = new Weaver.User(username, cuid(), "centaurus@univer.se")
      sameUsernameUser.signUp()
    ).catch(->
      done()
    )
    return
