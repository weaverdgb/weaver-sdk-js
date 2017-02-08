Weaver           = require('./Weaver')
writeFile        = require('./writeFile')
Error            = require('./Error')
WeaverError      = require('./WeaverError')
WeaverSystemNode = require('./WeaverSystemNode')
readFile         = require('./readFile')

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
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{id} at #{project} does not exits")
      else if Object.keys(buffer).length is 0
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{id} can\'t be retrieved because #{project} does not exists")
      else
        writeFile(path, buffer)
    )

  deleteFile: (fileName, project) ->
    coreManager = Weaver.getCoreManager()
    file = {
      fileName
      target: project
    }
    coreManager.deleteFile(file)

  deleteFileByID: (id, project) ->
    coreManager = Weaver.getCoreManager()
    file = {
      id
      target: project
    }
    coreManager.deleteFileByID(file)


module.exports = WeaverFile
