WeaverBase       = require('../Weaver')
SocketController = require('../SocketController')

class Weaver extends WeaverBase

  constructor: (opts) ->
    super(opts)
    @coreManager = new Weaver.CoreManager(SocketController)

module.exports = Weaver
