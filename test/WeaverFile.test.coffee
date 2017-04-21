require("./test-suite")

path     = require('path')
readFile = require('fs-readfile-promise')
fs       = require('fs')

describe 'WeaverFile test', ->
  file = ''
  tmpDir = path.join(__dirname,"../tmp")

  it 'should create a new file', ->
    this.timeout(15000) # This timeout is high because the 1st time minio takes more time (extra time creating a bucket)

    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')
    weaverFile.saveFile(fileTemp, 'weaverIcon.png')
    .then((res) ->
      file = res
      assert.equal(res.split('-')[1],'weaverIcon.png')
    )

  it 'should fail creating a new file, because the file does not exists on local machine', ->
    weaverFile = new Weaver.File()
    fileTemp = '../foo.bar'
    weaverFile.saveFile(fileTemp, 'foo.bar')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )


  it 'should fail retrieving a file, because the file does not exits on server', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFileByID(pathTemp,'foo.bar')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert(true)
    )



  it 'should retrieve a file by ID', ->
    this.timeout(15000)
    fileID = ''
    pathTemp = ''

    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')

    weaverFile.saveFile(fileTemp, 'weaverIcon.png')
    .then((res) ->
      fileID = res
      pathTemp = path.join(__dirname,"../tmp/id-#{fileID}")
      weaverFile.getFileByID(pathTemp,"#{fileID}".split('-')[0])
    ).then((res) ->
      readFile(res)
    ).then((destBuff) ->
      readFile(fileTemp)
      .then((originBuff) ->
        assert.equal(destBuff.toString(),originBuff.toString())
      )
    )

  it 'should fail retrieving a file by ID, because there is no file matching this ID', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFileByID(pathTemp,'f4k31d')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert(true)
    )

  it 'should delete a file by id', ->
    this.timeout(15000)
    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')
    weaverFile.saveFile(fileTemp, 'weaverIcon.png')
    .then((res) ->
      file = res
      assert.equal(res.split('-')[1],'weaverIcon.png')
      weaverFile.deleteFileByID("#{file}".split('-')[0])
    ).then( ->
      pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
      weaverFile.getFileByID(pathTemp,"#{file}".split('-')[0])
      .then((res) ->
        assert(false)
      ).catch((err) ->
        assert(true)
      )
    )
