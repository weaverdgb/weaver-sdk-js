# Libs
cuid   = require('cuid')
Weaver = require('./Weaver')
loki   = require('lokijs')
Error        = Weaver.LegacyError
WeaverError  = Weaver.Error
WeaverUser   = require('./WeaverUser')

class WeaverApplication

  constructor: () ->
    @weaverUser = new Weaver.User()

  createApplication: (user,applicationName,projectName) ->
    coreManager = Weaver.getCoreManager()
    @weaverUser.current(user)
    .then((accessToken) ->
      newApplication = {projectName,applicationName,accessToken}
      coreManager.createApplication(newApplication)
    )

# Export
module.exports = WeaverApplication

