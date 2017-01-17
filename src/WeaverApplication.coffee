# Libs
cuid   = require('cuid')
Weaver = require('./Weaver')
loki   = require('lokijs')
Error        = require('weaver-commons').Error
WeaverError  = require('weaver-commons').WeaverError
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
    ).catch((err) ->
      Promise.reject(err)
    )
    
# Export
Weaver.Application  = WeaverApplication
module.exports = WeaverApplication

