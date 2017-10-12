fs               = require('fs')
Promise          = require('bluebird')
Weaver           = require('./Weaver')
WeaverError      = require('./WeaverError')
Error            = require('./Error')
ss               = require('socket.io-stream')



class WeaverFile

  saveFile: (path, filename) ->
    stream = ss.createStream()
    fs.createReadStream(path).pipe(stream)

    Weaver.getCoreManager().uploadFile(stream, filename)


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
        reject(Error WeaverError.OTHER_CAUSE,error)
    )

  deleteFileByID: (id) ->
    file = {
      id
    }
    Weaver.getCoreManager().deleteFileByID(file)

module.exports = WeaverFile
