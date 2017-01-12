require("./test-suite")()

Weaver = require('./../src/Weaver')

describe 'WeaverSDK Application test', ->

  before (done) ->
    Weaver.initialize(WEAVER_ADDRESS).then(-> done())
    return


  it 'should get the weaver-server version', ->
    version = Weaver.getCoreManager().getCommController().GET('application.version')
    version.should.eventually.be.a('string')