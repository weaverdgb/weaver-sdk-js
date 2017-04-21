fs               = require('fs')
readFile         = require('fs-readfile-promise')
writeFile        = require('fs-writefile-promise')
WeaverRoot       = require('./WeaverRoot')
WeaverError      = require('./WeaverError')
Error            = require('./Error')



class WeaverFile extends WeaverRoot

  getClass: ->
    WeaverFile
  @getClass: ->
    WeaverFile

  saveFile: (path, fileName) ->
    formData = {
      file: fs.createReadStream(path)
      fileName
    }
    @getWeaver().getCoreManager().uploadFile(formData)


  getFileByID: (path, id) ->
    new Promise((resolve, reject) =>
      try
        payload = {
          id
        }
        fileStream = fs.createWriteStream(path)
        @getWeaver().getCoreManager().downloadFileByID(payload)
        .pipe(fileStream)
        fileStream.on('finish', ->
          resolve(fileStream.path)
        )
      catch error
        reject(Error WeaverError.OTHER_CAUSE,"Something went wrong")
    )

  deleteFileByID: (id) ->
    file = {
      id
    }
    @getWeaver().getCoreManager().deleteFileByID(file)

module.exports = WeaverFile
