require("./test-suite")

Weaver = require('./../src/Weaver')

describe 'Application test', ->

  it 'should get the weaver-server version', ->
    Weaver.serverVersion().then((version) ->
      version.should.be.a('string')
    )

  it 'should return server time', ->
    Weaver.getCoreManager().serverTime().then((time) ->
      console.log(time)
    )

  it 'should return server time again', ->
    Weaver.getCoreManager().serverTime().then((time) ->
      console.log(time)
    )
