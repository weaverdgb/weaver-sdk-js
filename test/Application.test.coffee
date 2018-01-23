weaver = require("./test-suite").weaver


describe 'Application test', ->

  it 'should get the weaver-server version', ->
    weaver.serverVersion().then((version) ->
      version.should.be.a('string')
    )

  it 'should return server time', ->
    weaver.getCoreManager().updateLocalTimeOffset()
    .then(->
      time = weaver.getCoreManager().serverTime()
    )

  it 'should return server time again', ->
    time = weaver.getCoreManager().serverTime()
