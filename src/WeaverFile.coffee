Weaver    = require('./Weaver')
readFile  = require('fs-readfile-promise')
writeFile = require('fs-writefile-promise')

class WeaverFile extends Weaver.SystemNode

  constructor: (@nodeId) ->
    super(@nodeId)

  @get: (nodeId) ->
    super(nodeId, WeaverFile)
    
  saveFile: (path, fileName, project) ->
    coreManager = Weaver.getCoreManager()
    readFile(path).then((file, err) ->
      if err
        err
      else
        fileBody = {
          buffer: file
          target: project
          fileName
        }
        coreManager.sendFile(fileBody)
    )
  
  getFile: (path, fileName, project) ->
    coreManager = Weaver.getCoreManager()
    file = {
      fileName
      target: project
    }
    coreManager.getFile(file)
    .then((buffer) ->
      writeFile(path, buffer)
    )

module.exports = WeaverFile
