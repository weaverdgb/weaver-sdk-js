weaver = require("./test-suite")


describe 'Application test', ->

  it 'should get the weaver-server version', ->
    weaver.serverVersion().then((version) ->
      version.should.be.a('string')
    )

  it 'should return server time', ->
    weaver.getCoreManager().updateLocalTimeOffset()
    .then(
      time = weaver.getCoreManager().serverTime()
      console.log(time)
    )

  it 'should return server time again', ->
    time = weaver.getCoreManager().serverTime()
    console.log(time)
