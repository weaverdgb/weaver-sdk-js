require("./test-suite")

Weaver = require('./../src/Weaver')

describe 'Application test', ->

  it 'should get the weaver-server version', ->
    Weaver.serverVersion().then((version) ->
      version.should.be.a('string')
    )
