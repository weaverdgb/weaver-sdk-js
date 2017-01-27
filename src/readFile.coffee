fs = require('graceful-fs')

module.exports =
  readFile = (filePath, options) ->
    new Promise((resolve, reject) ->
      fs.readFile(filePath, options, (err, data) ->
        if err
          reject(err)
        else
         resolve(data)
      )
    )