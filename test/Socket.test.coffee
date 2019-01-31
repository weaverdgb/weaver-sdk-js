weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'Socket Test', ->

  it 'should shout a message to clients', (done) ->
    Weaver.sniff((msg, data) ->
      assert.equal(data.msg, "Hello World")
      assert.equal(data.status, true)
      done()
    )

    Weaver.shout({msg:"Hello World", status:true})
    return
