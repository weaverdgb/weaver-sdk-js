Weaver           = require('./Weaver')
Error            = require('./Error')
WeaverError      = require('./WeaverError')


class WeaverFileBrowser

  constructor: (@nodeId) ->
    super(@nodeId)

  @get: (nodeId) ->
    super(nodeId, WeaverFile)

  saveFile: (file, fileName, project) ->
    coreManager = Weaver.getCoreManager()
    try
      fileBody = {
        buffer: file
        target: project
        fileName
      }
      coreManager.sendFile(fileBody)
    catch error
      if err.code is 'ENOENT'
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The file #{fileName} for upload at #{project} does not exits")
      else
        Promise.reject(Error WeaverError.OTHER_CAUSE,"Something went wrong trying to read the local file #{fileName}")

  getFile: (fileName, project) ->
    coreManager = Weaver.getCoreManager()
    file = {
      fileName
      target: project
    }
    coreManager.getFileBrowser(file)
    .then((buffer) ->
      if buffer.code?
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{fileName} at #{project} does not exits")
      else if Object.keys(buffer).length is 0
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{fileName} can\'t be retrieved because #{project} does not exists")
      else
        Buffer.from(buffer,'base64')
    )

  getFileByID: (id, project) ->
    coreManager = Weaver.getCoreManager()
    file = {
      id
      target: project
    }
    coreManager.getFileByIDBrowser(file)
    .then((buffer) ->
      if buffer.code?
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{id} at #{project} does not exits")
      else if Object.keys(buffer).length is 0
        Promise.reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The requested file #{id} can\'t be retrieved because #{project} does not exists")
      else
        Buffer.from(buffer,'base64')
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


module.exports = WeaverFileBrowser
