fs               = require('fs')
path             = require('path')
Promise          = require('bluebird')
Weaver           = require('./Weaver')
WeaverError      = require('./WeaverError')
Error            = require('./Error')
ss               = require('socket.io-stream')
EventEmitter     = require('events').EventEmitter

class WeaverFile extends EventEmitter

  constructor: (@filePath, @fileId) ->
    super
    @_local = false
    @_stored = false
    if File? and @filePath instanceof File
      @fileSize = @filePath.size
      @fileName = @filePath.name
      @fileExt = path.extname(@filePath.name)
      @_local = true
    else
      @_getFileStats(@filePath) if @filePath? and @_fileExists(@filePath)

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
  # Gets the extension
  # @return {String} The extension of the file
  ###
  extension: ->
    @fileExt

  ###*
  # Gets the filesize
  # @return {Integer} The filesize in bytes
  ###
  size: ->
    @fileSize

  ###*
  # Set the path for the file. This does not directly check
  # whether the file exists
  # @param {String} filepath The path for the file
  # @returns {WeaverFile} The current WeaverFile instance
  ###
  setPath: (filePath) ->
    if @_fileExists(filePath)
      @_getFileStats(filePath)
      @filePath = filePath
    else
      @_local = false
    @

  ###*
  # Set the name for the file. You do not have to specify the filename
  # through this function when supplying a filepath.
  # @param {String} fileName The string to set as the name
  # @returns {WeaverFile} The current WeaverFile instance
  ###
  setName: (fileName) ->
    @fileName = fileName
    @

  ###*
  # Set the extension of the file.
  #
  ###
  setExtension: (extension) ->
    @fileExt = extension
    @

  ###*
  # Private function to check if the file exists on the disk.
  # whether the file exists
  # @param {String} filePath The path to check
  # @returns {fs.Stats}
  ###
  _fileExists: (filePath) ->
    fs.existsSync(filePath)

  _getFileStats: (filePath) ->
    try
      _stats = fs.statSync(filePath)
      @setName(path.basename(filePath))
      @setExtension(path.extname(filePath))
      @fileSize = _stats.size
      @_local = true
    catch err
      throw new Error(Weaver.Error.FILE_NOT_EXISTS_ERROR)

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
        fileExt = path.extname(file.name)
        storedFile = new WeaverFile(null, fileId)
        storedFile.setName(fileName)
        storedFile.setExtension(fileExt)
        storedFile.fileSize = file.size
        storedFile._stored = true
        files.push(storedFile)

      files
    )

  ###*
  # Uploads the instance of WeaverFile to the object storage
  # @returns {Promise<WeaverFile>} The stored WeaverFile
  ###
  upload: ->
    if (File? and @filePath instanceof File) or @_fileExists(@filePath)
      stream = ss.createStream()
      readStream = if File? and @filePath instanceof File then ss.createBlobReadStream(@filePath) else fs.createReadStream(@filePath)
      _uploadedBytes = 0

      readStream.on('data', (chunk) =>
        _uploadedBytes += chunk.length
        percentage = Math.floor((_uploadedBytes / @fileSize) * 100)
        @emit('upload progress', percentage)
      )

      readStream.pipe(stream)
      Weaver.getCoreManager().uploadFile(stream, @fileName)
      .then((res) =>
        @fileId = res.id
        @_stored = true
        @
      )
    else
      Promise.reject({code: Weaver.Error.FILE_NOT_EXISTS_ERROR, message: "File does not exist!"})

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
        _downloadedBytes = 0
        writeStream = fs.createWriteStream(@filePath)

        stream.on('data', (chunk) =>
          _downloadedBytes += chunk.length
          percentage = if @fileSize? then Math.floor((_downloadedBytes / @fileSize) * 100) else 'unknown'
          @emit('download progress', percentage)
        )

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
  # Download progress won't work this way
  # @param {String} id The WeaverFile ID
  # @returns {WeaverFile} A new WeaverFile instance
  ###
  @get: (id) ->
    new WeaverFile(undefined, id)

  ###*
  # Remove a file from the object storage
  # This method will never delete anything from the local disk
  # @returns {Promise}
  ###
  destroy: ->
    Weaver.getCoreManager().deleteFile(@fileId)

module.exports = WeaverFile
