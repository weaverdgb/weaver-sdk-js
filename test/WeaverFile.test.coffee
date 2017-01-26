require("./test-suite")
path = require('path')

describe 'WeaverFile test', ->

  it 'should create a new file', ->
    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')
    weaverFile.saveFile(fileTemp, 'weaver-icon.png', 'area51').then((res) ->
      assert.equal(res,'file uploaded ok')
    )
  
  it 'should fails create a new file, because the file does not exits on local machine', ->
    weaverFile = new Weaver.File()
    fileTemp = '../foo.bar'
    weaverFile.saveFile(fileTemp, 'foo.bar', 'area51').then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )
  
  it 'should retrieve a file', ->
    weaverFile = new Weaver.File()
    pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
    weaverFile.getFile(pathTemp,'weaver-icon.png','area51').then((res) ->
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