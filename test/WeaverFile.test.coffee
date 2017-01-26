require("./test-suite")
path = require('path')

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
    pathTemp = path.join(__dirname,"../tmp/#{file}")
    weaverFile.getFile(pathTemp,"#{file}",'area51').then((res) ->
      assert.equal(res,pathTemp)
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
    weaverFile.getFileByID(pathTemp,"#{file}".split('-')[0],'area51').then((res) ->
      assert.equal(res,pathTemp)
    )
  
  # it 'should fails retrieving a file by ID, because there is no file matching this ID', ->
  #   weaverFile = new Weaver.File()
  #   pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
  #   weaverFile.getFileByID(pathTemp,'f4k31d','area51')
  #   .then((res) ->
  #     assert(false)
  #   ).catch((err) ->
  #     console.log err
  #     assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
  #   )
    
  