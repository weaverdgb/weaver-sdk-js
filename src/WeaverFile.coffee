Weaver           = require('./Weaver')
writeFile        = require('fs-writefile-promise')
Error            = require('./Error')
WeaverError      = require('./WeaverError')
readFile         = require('fs-readfile-promise')
fs               = require('fs')
CoreManager      = Weaver.getCoreManager()


class WeaverFile

  saveFile: (path, fileName) ->
    formData = {
      file: fs.createReadStream(path)
      fileName
    }
    CoreManager.uploadFile(formData)


  getFileByID: (path, id) ->
    new Promise((resolve, reject) =>
      try
        payload = {
          id
        }
        fileStream = fs.createWriteStream(path)
        CoreManager.downloadFileByID(payload)
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
    CoreManager.deleteFileByID(file)

module.exports = WeaverFile
