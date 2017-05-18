fs               = require('fs')
Weaver           = require('./Weaver')
WeaverError      = require('./WeaverError')
Error            = require('./Error')



class WeaverFile

  saveFile: (path, fileName) ->
    formData = {
      file: fs.createReadStream(path)
      fileName
    }
    Weaver.getCoreManager().uploadFile(formData)


  getFileByID: (path, id) ->
    new Promise((resolve, reject) =>
      try
        payload = {
          id
        }
        fileStream = fs.createWriteStream(path)
        Weaver.getCoreManager().downloadFileByID(payload)
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
    Weaver.getCoreManager().deleteFileByID(file)

module.exports = WeaverFile
