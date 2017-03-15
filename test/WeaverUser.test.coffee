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

      # Sign out and sign in again
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


  it 'should create the admin user upon initialization', (done) ->
    done()

  it 'should create the admin role upon initialization', (done) ->
    done()

  it 'should allow only the admin to wipe a project', (done) ->
    done()

  it 'should create a new project by default on private ACL', (done) ->
    done()

  it 'should deny other users from reading project nodes on private ACL', (done) ->
    done()

  it 'should deny other users from writing project nodes on private ACL', (done) ->
    done()

  it 'should allow other users from reading project nodes on public ACL', (done) ->
    done()

  it 'should allow other users from writing project nodes on public ACL', (done) ->
    done()

  it 'should allow other users from reading project nodes on role ACL ', (done) ->
    done()

  it 'should allow other users from writing project nodes on role ACL ', (done) ->
    done()

  it 'should allow other users from reading project nodes on child role ACL ', (done) ->
    done()

  it 'should allow other users from writing project nodes on child role ACL ', (done) ->
    done()

  it 'should restrict read access when getting nodes', (done) ->
    done()

  it 'should restrict read access when querying nodes', (done) ->
    done()

  it 'should restrict write access when writing nodes', (done) ->
    done()


  it 'should fail signing up with an existing username', (done) ->
    username = cuid()
    password = cuid()
    user     = new Weaver.User(username, password, "centaurus@univer.se")

    Weaver.signOut().then(->
      user.signUp()
    ).then(->
      Weaver.signOut()
    ).then(->
      adminSignin()
    ).then(->
      sameUsernameUser = new Weaver.User(username, cuid(), "centaurus@univer.se")
      sameUsernameUser.signUp()
    ).catch(->
      done()
    )
    return
