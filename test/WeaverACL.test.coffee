weaver = require("./test-suite")
Weaver = weaver.getClass()

describe 'WeaverACL test', ->

  it 'should create a new ACL', ->
    acl = new Weaver.ACL()

    acl.save().then((acl) ->
      Weaver.ACL.load(acl.id())
    ).then((loadedACL) ->
      assert.equal(loadedACL.id(), acl.id())
    ).catch((Err) -> console.log(Err))
