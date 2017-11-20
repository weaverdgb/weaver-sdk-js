fs               = require('fs')
path             = require('path')
Promise          = require('bluebird')
Weaver           = require('./Weaver')
WeaverError      = require('./WeaverError')
Error            = require('./Error')
ss               = require('socket.io-stream')

class WeaverFile

  constructor: (@filePath, @fileId) ->
    @fileName = path.basename(@filePath) if @filePath?
    @filePath = path.resolve(@filePath) if @filePath?
    @_local = @filePath?
    @_stored = false

  ###*
  # Retreive the ID of the file
  # @returns {String} The ID of the file
  ###
  id: ->
    @fileId

  ###*
  # Retreive the name of the file
  # @returns {String} The name of the file
  ###
  name: ->
    @fileName

  ###*
  # Retreive filepath
  # @returns {String} The filepath
  ###
  path: ->
    @filePath

  ###*
  # Set the path for the file. This does not directly check
  # whether the file exists
  # @param {String} filepath The path for the file
  # @returns {WeaverFile} The current WeaverFile instance
  ###
  setPath: (@filePath) ->
    @filePath = path.resolve(filePath)
    @local = @filePath?
    @name = path.basename(@filePath)
    @

  ###*
  # Set the name for the file. You do not have to specify the filename
  # through this function.
  # @param {String} fileName The string to set as the name
  # @returns {WeaverFile} The current WeaverFile instance
  ###
  setName: (fileName) ->
    @fileName = fileName
    @

  ###*
  # Private function to check if the file exists on the disk.
  # whether the file exists
  # @param {String} filePath The path to check
  # @returns {Promise}
  ###
  _fileExists: (filePath) ->
    new Promise((resolve, reject) ->
      fs.stat(filePath, (err) ->
        return reject({code: Weaver.Error.FILE_NOT_EXISTS_ERROR, message: 'File does not exists'}) if err?
        resolve()
      )
    )

  ###*
  # List all files in the object storage
  # @returns {Promise<Array<WeaverFile>>} Promise that resolves with
  # an array of WeaverFile instances
  ###
  @list: ->
    Weaver.getCoreManager().listFiles().then((storedFiles) ->
      files = []
      for file in storedFiles
        fileName = file.name.substring(file.name.indexOf('-') + 1)
        fileId = file.name.slice(0, file.name.indexOf('-'))
        storedFile = new WeaverFile(null, fileId)
        storedFile.setName(fileName)
        storedFile._stored = true
        files.push(storedFile)

      files
    )

  ###*
  # Uploads the instance of WeaverFile to the object storage
  # @returns {Promise<WeaverFile>} The stored WeaverFile
  ###
  upload: ->
    @_fileExists(@filePath).then(=>
      stream = ss.createStream()
      fs.createReadStream(@filePath).pipe(stream)
      Weaver.getCoreManager().uploadFile(stream, @fileName)
    ).then((res) =>
      @fileId = res.id
      @_stored = true
      @
    )

  ###*
  # Downloads a WeaverFile instance from the object storage
  # @param {String} filePath The path so save the file to.
  # @returns {Promise<WeaverFile>} The instance of the downloaded WeaverFile
  ###
  download: (filePath) ->
    @filePath = path.resolve(filePath)
    Weaver.getCoreManager()
      .downloadFile(@fileId)
      .then((stream) =>
        writeStream = fs.createWriteStream(@filePath)
        stream.pipe(writeStream)
        new Promise((resolve, reject) =>
          writeStream.on('finish', =>
            @_stored = true
            @_local = true
            resolve(@)
          )
        )
      )

  ###*
  # Returns a WeaverFile instance with only the ID set
  # @param {String} id The WeaverFile ID
  # @returns {WeaverFile} A new WeaverFile instance
  ###
  @get: (id) ->
    new WeaverFile(null, id)

  ###*
  # Remove a file from the object storage
  # This method will never delete anything from the local disk
  # @returns {Promise}
  ###
  destroy: ->
    Weaver.getCoreManager().deleteFile(@fileId)

module.exports = WeaverFile
