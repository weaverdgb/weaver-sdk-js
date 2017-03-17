Weaver           = require('./Weaver')
writeFile        = require('fs-writefile-promise')
Error            = require('./Error')
WeaverError      = require('./WeaverError')
readFile         = require('fs-readfile-promise')
fs               = require('fs')


class WeaverFile extends Weaver.Node

  constructor: (@nodeId) ->
    super(@nodeId)

  @get: (nodeId) ->
    super(nodeId, WeaverFile)

  saveFile: (path, fileName, project, authToken) ->
    coreManager = Weaver.getCoreManager()
    formData = {
      file: fs.createReadStream(path)
      authToken
      target:project
      fileName
    }
    coreManager.uploadFile(formData)

  getFile: (path, fileName, project, authToken) ->
    coreManager = Weaver.getCoreManager()
    new Promise((resolve, reject) =>
      try
        payload = {
          fileName
          target: project
          authToken
        }
        fileStream = fs.createWriteStream(path)
        coreManager.downloadFile(JSON.stringify(payload))
        .pipe(fileStream)
        fileStream.on('finish', ->
          resolve(fileStream.path)
        )
      catch error
        reject(Error WeaverError.OTHER_CAUSE,"Something went wrong")
    )

  getFileByID: (path, id, project, authToken) ->
    coreManager = Weaver.getCoreManager()
    new Promise((resolve, reject) =>
      try
        payload = {
          id
          target: project
          authToken
        }
        fileStream = fs.createWriteStream(path)
        coreManager.downloadFileByID(JSON.stringify(payload))
        .pipe(fileStream)
        fileStream.on('finish', ->
          resolve(fileStream.path)
        )
      catch error
        reject(Error WeaverError.OTHER_CAUSE,"Something went wrong")
    )

  deleteFile: (fileName, project, authToken) ->
    coreManager = Weaver.getCoreManager()
    file = {
      fileName
      target: project
      authToken
    }
    coreManager.deleteFile(file)

  deleteFileByID: (id, project, authToken) ->
    coreManager = Weaver.getCoreManager()
    file = {
      id
      target: project
      authToken
    }
    coreManager.deleteFileByID(file)

module.exports = WeaverFile
