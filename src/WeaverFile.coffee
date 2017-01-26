Weaver           = require('./Weaver')
readFile         = require('fs-readfile-promise')
writeFile        = require('fs-writefile-promise')
Error            = require('./Error')
WeaverError      = require('./WeaverError')
WeaverSystemNode = require('./WeaverSystemNode')

class WeaverFile extends Weaver.SystemNode

  constructor: (@nodeId) ->
    super(@nodeId)

  @get: (nodeId) ->
    super(nodeId, WeaverFile)
    
  saveFile: (path, fileName, project) ->
    coreManager = Weaver.getCoreManager()
    readFile(path)
    .then((file) ->
      fileBody = {
        buffer: file
        target: project
        fileName
      }
      coreManager.sendFile(fileBody)
    ).catch((err) ->
      if err.code is 'ENOENT'
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The file #{fileName} for upload at #{project} does not exits")
      else
        Promise.reject(Error WeaverError.OTHER_CAUSE,"Something went wrong trying to read the local file #{fileName}")
    )
  
  getFile: (path, fileName, project) ->
    coreManager = Weaver.getCoreManager()
    file = {
      fileName
      target: project
    }
    coreManager.getFile(file)
    .then((buffer) ->
      if buffer.code?
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{fileName} at #{project} does not exits")
      else if Object.keys(buffer).length is 0
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{fileName} can\'t be retrieved because #{project} does not exists")
      else
        writeFile(path, buffer)
    ).catch((err) ->
      Promise.reject(err)
    )
    
  getFileByID: (path, id, project) ->
    coreManager = Weaver.getCoreManager()
    file = {
      id
      target: project
    }
    coreManager.getFileByID(file)
    .then((buffer) ->
      if buffer.code?
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{fileName} at #{project} does not exits")
      else if Object.keys(buffer).length is 0
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{fileName} can\'t be retrieved because #{project} does not exists")
      else
        writeFile(path, buffer)
    ).catch((err) ->
      Promise.reject(err)
    )
    
module.exports = WeaverFile
