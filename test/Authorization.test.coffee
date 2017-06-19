weaver = require("./test-suite")
Weaver = require('../src/Weaver')
Promise = require('bluebird')

describe 'Authorization test', ->
  it 'should test stuff', ->
    testUser = new Weaver.User('testuser', 'testpassword', 'email@dontevenvalidate.com')
    testUser.create().then((user) ->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername('testuser', 'testpassword')
    ).then(->
      p = new Weaver.Project('doesnt matter', 'this-should-fail')
      p.create()
    ).then(->
      assert.fail()
    ).catch((err)->
      expect(err).to.have.property('message').match(/Permission denied/)
    )
