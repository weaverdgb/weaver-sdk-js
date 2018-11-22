WeaverBase       = require('../Weaver')
SocketController = require('../SocketControllerWithStream')

class Weaver extends WeaverBase

  constructor: (opts) ->
    super(opts)

    @File        = Weaver.File
    @Plugin      = Weaver.Plugin
    @coreManager = new Weaver.CoreManager(SocketController)

module.exports = Weaver

module.exports.Plugin = require('../WeaverPlugin')
module.exports.File   = require('../WeaverFile')
