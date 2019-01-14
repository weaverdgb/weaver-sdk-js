WeaverBase       = require('../Weaver')
SocketController = require('../SocketControllerWithStream')

class Weaver extends WeaverBase

  constructor: (opts) ->
    super(opts)

    Weaver.instance = @

    @File        = Weaver.File
    @Plugin      = Weaver.Plugin
    @coreManager = new Weaver.CoreManager(SocketController)

module.exports = Weaver
window.Weaver  = Weaver if window?  # Browser

module.exports.Plugin = require('../WeaverPlugin')
module.exports.File   = require('../WeaverFile')
