weaver  = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
cuid    = require('cuid')
Weaver  = require('../src/Weaver')
Promise = require('bluebird')

describe 'WeaverUser Test', ->
  beforeEach ->
    wipeCurrentProject()

  it 'should allow a user to list other users in a project', ->
    testUser = new Weaver.User('in-project', 'testpassword', 'email@dontevenvalidate.com')
    testUser2 = new Weaver.User('in-project2', 'testpassword', 'email@dontevenvalidate.com')
    testUser3 = new Weaver.User('not-in-project', 'testpassword', 'email@dontevenvalidate.com')
    Promise.all([testUser.create(), testUser2.create(), testUser3.create()]).then( ->
      Weaver.ACL.load(weaver.currentProject().acl.id)
    ).then((acl) ->
      acl.setUserWriteAccess(testUser, true)
      acl.setUserWriteAccess(testUser2, true)
      acl.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('in-project', 'testpassword')
    ).then(->
      Weaver.User.listProjectUsers()
    ).then((users) ->
      (i.username for i in users)
    ).should.eventually.eql(['in-project', 'in-project2'])


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



  it 'should sign out a user', ->
    weaver.signOut().then( ->
      # Writing is now not permitted
      node = new Weaver.Node()
      node.save()
    ).catch((error) ->
      assert.equal(error.code,Weaver.Error.OTHER_CAUSE)
    )

  it.skip 'should sign in the session if token is saved', ->
    # TODO: Perhaps localforage is better for this instead of loki
    return

  it.skip 'should create a user without signing in', ->
    return

  it 'should fail to login with incorrect username', ->
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
      assert.equal(err.code, Weaver.Error.INVALID_USERNAME_PASSWORD)
    )

  it 'should fail to login with incorrect password', ->
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
      assert.equal(err.code, Weaver.Error.INVALID_USERNAME_PASSWORD)
    )

  it 'should fail to login with non valid token', (done) ->
    weaver.signOut().then(->
      weaver.signInWithToken('some invalid token')
    ).then((user) ->
      assert(false)
    ).catch((err) ->
      done()
    )
    return

  it 'should fail to login with non existing user', ->
    weaver.signOut().then(->
      # Sign in
      weaver.signInWithUsername('username', 'password')
    ).catch((err) ->
      assert.equal(err.code, Weaver.Error.INVALID_USERNAME_PASSWORD)
    )

  it 'should fail to login with NoSQL injection', ->
    weaver.signOut().then(->
      # Sign in
      weaver.signInWithUsername({"username": {"$regex": ["a?special-user","i"]}}, 'password')
    ).catch((err) ->
      assert.equal(err.code, Weaver.Error.INVALID_USERNAME_PASSWORD)
    )

  it 'should sign in a user with valid alphanumeric characters and - _', ->
    username = 'fo_0-B4r'
    password = 'secretSauce123'
    user = new Weaver.User(username, password, "centaurus@univer.se")
    user.signUp()
    .then( =>
      weaver.signInWithUsername(username,password)
    ).then((user) ->
      assert.equal(username, user.username)
    )

  it 'should fail to login with empty username', ->
    weaver.signOut().then(->
      # Sign in
      weaver.signInWithUsername('', 'password')
    ).catch((err) ->
      assert.equal(err.code, Weaver.Error.INVALID_USERNAME_PASSWORD)
    )

  it 'should fail to login with blanck string as username', ->
    weaver.signOut().then(->
      weaver.signInWithUsername('        ', 'password')
    ).catch((err) ->
      assert.equal(err.code, Weaver.Error.INVALID_USERNAME_PASSWORD)
    )

  it 'should fail to login with non alphanumeric characters for username but - _', ->
    weaver.signOut().then(->
      # Sign in
      weaver.signInWithUsername('foo*bar', 'password')
    ).catch((err) ->
      assert.equal(err.code, Weaver.Error.INVALID_USERNAME_PASSWORD)
    )

  it 'should fail to login with NoSQL injection', ->
    weaver.signOut().then(->
      # Sign in
      weaver.signInWithUsername({"username": {"$regex": ["a?special-user","i"]}}, 'password')
    ).catch((err) ->
      assert.equal(err.code, Weaver.Error.INVALID_USERNAME_PASSWORD)
    )

  it 'should list all users', ->
    Promise.map([
      new Weaver.User('abcdef', '123456', 'ghe')
      new Weaver.User('doddye', '123456', 'ghe')
      ], (u) -> u.create()).then(->
      Weaver.User.list()
    ).then((users) ->
      assert.equal(users.length, 2)
    )

  it 'should get all roles for user', ->
    r1 = new Weaver.Role('role1')
    r2 = new Weaver.Role('role2')
    r3 = new Weaver.Role('role3')

    u = new Weaver.User('abcdef', '123456', 'ghe')
    u.create().then(->

      r1.addUser(u)
      r2.addUser(u)

      Promise.map([r1,r2,r3], (r) -> r.save())
    ).then(->
      u.getRoles()
    ).then((roles) ->
      assert.equal(roles.length, 2)
      assert.equal(roles[0].name, 'role1')
      assert.equal(roles[1].name, 'role2')
    )

  it.skip 'should create the admin user upon initialization', (done) ->

  it.skip 'should create the admin role upon initialization', (done) ->

  it 'should allow only the admin to wipe all', ->
    user = new Weaver.User("username", "centaurus123", "centaurus@univer.se")
    weaver.signOut()
    .then(->
      user.signUp()
    ).then(->
      weaver.wipe()
    ).then(->
      assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should allow only the admin to wipe a single project', ->
    user = new Weaver.User("username", "centaurus123", "centaurus@univer.se")
    weaver.signOut()
    .then(->
      user.signUp()
    ).then(->
      weaver.currentProject().wipe()
    ).then(->
      assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should allow only the admin to wipe all projects', ->
    user = new Weaver.User("username", "centaurus123", "centaurus@univer.se")
    weaver.signOut()
    .then(->
      user.signUp()
    ).then(->
      weaver.coreManager.wipeProjects()
    ).then(->
      assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should allow only the admin to destroy all projects', ->
    user = new Weaver.User("username", "centaurus123", "centaurus@univer.se")
    weaver.signOut()
    .then(->
      user.signUp()
    ).then(->
      weaver.coreManager.destroyProjects()
    ).then(->
      assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should allow only the admin to wipe all users', ->
    user = new Weaver.User("username", "centaurus123", "centaurus@univer.se")
    weaver.signOut()
    .then(->
      user.signUp()
    ).then(->
      weaver.coreManager.wipeUsers()
    ).then(->
      assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

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
