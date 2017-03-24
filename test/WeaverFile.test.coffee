require("./test-suite")

path     = require('path')
readFile = require('fs-readfile-promise')
fs       = require('fs')

describe 'WeaverFile test', ->
  file = ''
  tmpDir = path.join(__dirname,"../tmp")

  it 'should create a new file', ->
    this.timeout(10000) # This timeout is high because the 1st time minio takes more time (extra time creating a bucket)

    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')
    weaverFile.saveFile(fileTemp, 'weaverIcon.png', 'area51',  'eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      file = res
      assert.equal(res.split('-')[1],'weaverIcon.png')
    )

  it 'should fail creating a new file, because the file does not exists on local machine', ->
    weaverFile = new Weaver.File()
    fileTemp = '../foo.bar'
    weaverFile.saveFile(fileTemp, 'foo.bar', 'area51', 'eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should retrieve a file by fileName', ->
    if not fs.existsSync(tmpDir)
      fs.mkdirSync(tmpDir)

    weaverFile = new Weaver.File()
    destFile = path.join(__dirname,"../tmp/#{file}")
    originFile = path.join(__dirname,'../icon.png')
    weaverFile.getFile(destFile,"#{file}",'area51','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      readFile(res)
    ).then((destBuff) ->
      readFile(originFile)
    )
    .then((originBuff) ->
      assert.equal(destBuff.toString(),originBuff.toString())
    )


  it 'should fail retrieving a file, because the file does not exits on server', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFile(pathTemp,'foo.bar','area51','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert(true)
    )

  # Delete this because already taken care of
  it 'should fail retrieving a file, because the project does not exits on server', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFile(pathTemp,'weaver-icon.png','fooBar','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert(true)
      # assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should retrieve a file by ID', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,"../tmp/id-#{file}")
    originFile = path.join(__dirname,'../icon.png')
    weaverFile.getFileByID(pathTemp,"#{file}".split('-')[0],'area51','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      readFile(res)
    ).then((destBuff) ->
      readFile(originFile)
      .then((originBuff) ->
        assert.equal(destBuff.toString(),originBuff.toString())
      )
    )

  it 'should fail retrieving a file by ID, because there is no file matching this ID', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFileByID(pathTemp,'f4k31d','area51','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert(true)
      # assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should delete a file by name', ->
    weaverFile = new Weaver.File()
    weaverFile.deleteFile("#{file}",'area51','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then( ->
      pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
      weaverFile.getFile(pathTemp,"#{file}",'area51')
      .then((res) ->
        assert(false)
      ).catch((err) ->
        assert(true)
      )
    )

  it 'should delete a file by id', ->
    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')
    weaverFile.saveFile(fileTemp, 'weaverIcon.png', 'area51','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      file = res
      assert.equal(res.split('-')[1],'weaverIcon.png')
      weaverFile.deleteFileByID("#{file}",'area51','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
      .then( ->
        pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
        weaverFile.getFile(pathTemp,"#{file}".split('-')[0],'area51')
        .then((res) ->
          assert(false)
        ).catch((err) ->
          assert(true)
          # assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
        )
      )
    )

  it 'should fails trying to delete a file because the project does not exists', ->
    weaverFile = new Weaver.File()
    weaverFile.deleteFile("#{file}",'area69','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should fails trying to delete a file by ID because the project does not exists', ->
    weaverFile = new Weaver.File()
    weaverFile.deleteFileByID("#{file}",'area69','eyJhbGciOiJSUzI1NiJ9.eyIkaW50X3Blcm1')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  # TODO: Deal retrieving errors from server for the new endpoints
