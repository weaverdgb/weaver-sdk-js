weaver  = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
cuid    = require('cuid')
Weaver  = require('../src/Weaver')
Promise = require('bluebird')
path    = require('path')
supertest = require('supertest')


weaverServer = supertest.agent(WEAVER_ENDPOINT)

describe 'Weaver Tests dealing with REST API', ->
  beforeEach ->
    wipeCurrentProject()

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

  it 'should retrieve the list of users providing the authtoken on Headers', ->
    Promise.map([
      new Weaver.User('abcdef', '123456', 'ghe')
      new Weaver.User('doddye', '123456', 'ghe')
      ], (u) -> u.create()).then(->
      Weaver.User.list()
    ).then((users) ->
      assert.equal(users.length, 2)
      weaverServer
      .get("/users")
      .set({authorization:"Bearer #{weaver.currentUser().authToken}"})
      .expect(200)
      .then((res) ->
        ans = JSON.parse(res.text)
        assert.equal(ans.length,2)
      )
    )

  ################################
  # LEGACY TESTS FOR WEAVER FILE #
  ################################
  it 'should upload a file through the legacy API', ->
    weaverServer
    .post('/upload')
    .field('fileName', 'icon.png')
    .field('target', 'area51')
    .field('authToken', weaver.currentUser().authToken)
    .attach('file',path.join(__dirname,'../icon.png'))
    .expect(200)
    .then((res) ->
      file = res.text
      assert.match(file, /-icon.png/)
    )
