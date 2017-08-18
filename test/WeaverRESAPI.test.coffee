weaver  = require("./test-suite")
cuid    = require('cuid')
Weaver  = require('../src/Weaver')
Promise = require('bluebird')
supertest = require('supertest')


weaverServer = supertest.agent(WEAVER_ENDPOINT)

describe 'Weaver Tests dealing with REST API', ->

  it 'should retrieve the list of users providing the authtoken on query param', ->
    Promise.map([
      new Weaver.User('abcdef', '123456', 'ghe')
      new Weaver.User('doddye', '123456', 'ghe')
      ], (u) -> u.create()).then(->
      Weaver.User.list()
    ).then((users) ->
      assert.equal(users.length, 2)
      weaverServer
      .get("/users?payload={\"authToken\":\"#{weaver.currentUser().authToken}\"}")
      .expect(200)
      .then((res) ->
        ans = JSON.parse(res.text)
        assert.equal(ans.length,2)
      )
    )

  it.skip 'should retrieve the list of users providing the authtoken on Headers', ->
    Promise.map([
      new Weaver.User('abcdef', '123456', 'ghe')
      new Weaver.User('doddye', '123456', 'ghe')
      ], (u) -> u.create()).then(->
      Weaver.User.list()
    ).then((users) ->
      assert.equal(users.length, 2)
      weaverServer
      .get("/users")
      .set({authtoken:weaver.currentUser().authToken})
      .expect(200)
      .then((res) ->
        ans = JSON.parse(res.text)
        assert.equal(ans.length,2)
      )
    )
