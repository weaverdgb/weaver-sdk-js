require("./test-suite")
path = require('path')
readFile = require('fs-readfile-promise')

describe 'WeaverFile test', ->
  file = ''

  it 'should create a new file', ->
    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')
    weaverFile.saveFile(fileTemp, 'weaverIcon.png', 'area51').then((res) ->
      file = res
      assert.equal(res.split('-')[1],'weaverIcon.png')
    )
  
  it 'should fails create a new file, because the file does not exits on local machine', ->
    weaverFile = new Weaver.File()
    fileTemp = '../foo.bar'
    weaverFile.saveFile(fileTemp, 'foo.bar', 'area51').then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )
  
  it 'should retrieve a file by fileName', ->
    weaverFile = new Weaver.File()
    destFile = path.join(__dirname,"../tmp/#{file}")
    originFile = path.join(__dirname,'../icon.png')
    weaverFile.getFile(destFile,"#{file}",'area51')
    .then((res) ->
      readFile(res)
    ).then((destBuff) ->
      readFile(originFile)
      .then((originBuff) ->
        assert.equal(destBuff.toString(),originBuff.toString())
      )
    )
  
  
  it 'should fails retrieving a file, because the file does not exits on server', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFile(pathTemp,'foo.bar','area51')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )
  
  it 'should fails retrieving a file, because the project does not exits on server', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFile(pathTemp,'weaver-icon.png','fooBar')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )
  
  it 'should retrieve a file by ID', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,"../tmp/id-#{file}")
    originFile = path.join(__dirname,'../icon.png')
    weaverFile.getFileByID(pathTemp,"#{file}".split('-')[0],'area51')
    .then((res) ->
      readFile(res)
    ).then((destBuff) ->
      readFile(originFile)
      .then((originBuff) ->
        assert.equal(destBuff.toString(),originBuff.toString())
      )
    )
  
  it 'should fails retrieving a file by ID, because there is no file matching this ID', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFileByID(pathTemp,'f4k31d','area51')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )
    
  it 'should deletes a file by name', ->
    weaverFile = new Weaver.File()
    weaverFile.deleteFile("#{file}",'area51')
    .then( ->
      pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
      weaverFile.getFile(pathTemp,"#{file}",'area51')
      .then((res) ->
        assert(false)
      ).catch((err) ->
        assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
      )
    )
    
  it 'should deletes a file by id', ->
    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')
    weaverFile.saveFile(fileTemp, 'weaverIcon.png', 'area51').then((res) ->
      file = res
      assert.equal(res.split('-')[1],'weaverIcon.png')
      weaverFile.deleteFileByID("#{file}",'area51')
      .then( ->
        pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
        weaverFile.getFile(pathTemp,"#{file}".split('-')[0],'area51')
        .then((res) ->
          assert(false)
        ).catch((err) ->
          assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
        )
      )
    )
    
  it 'should fails trying to delete a file because the project does not exists', ->
    weaverFile = new Weaver.File()
    weaverFile.deleteFile("#{file}",'area69')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )
    
  it 'should fails trying to delete a file by ID because the project does not exists', ->
    weaverFile = new Weaver.File()
    weaverFile.deleteFileByID("#{file}",'area69')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )
    