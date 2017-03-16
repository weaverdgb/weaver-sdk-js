return
require("./test-suite")
path = require('path')
readFile = require('fs-readfile-promise')
fs = require('fs')

###
 This test class is very tricky. Because the class it supose to be
 alive just on web browser environment.
 TODO: take a look for testing this.
###


describe 'weaverFileBrowser test', ->
  file = ''
  tmpDir = path.join(__dirname,"../tmp")

  it 'should create a new file', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    fileTemp = path.join(__dirname,'../icon.png')
    readFile(fileTemp)
    .then((fileBuffer) ->
      weaverFileBrowser.saveFile(fileBuffer, 'weaverIcon.png', 'area51').then((res) ->
        file = res
        assert.equal(res.split('-')[1],'weaverIcon.png')
      )
    )

  it 'should retrieve a file by fileName', ->
    if !fs.existsSync(tmpDir)
      fs.mkdirSync(tmpDir)
    weaverFileBrowser = new Weaver.FileBrowser()
    destFile = path.join(__dirname,"../tmp/#{file}")
    originFile = path.join(__dirname,'../icon.png')
    weaverFileBrowser.getFile("#{file}",'area51')
    .then((res) ->
      readFile(originFile)
      .then((originBuff) ->
        assert.equal(res.toString(),originBuff.toString())
      )
    )


  it 'should fails retrieving a file, because the file does not exits on server', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    weaverFileBrowser.getFile('foo.bar','area51')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should fails retrieving a file, because the project does not exits on server', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    weaverFileBrowser.getFile('weaver-icon.png','fooBar')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should retrieve a file by ID', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    originFile = path.join(__dirname,'../icon.png')
    weaverFileBrowser.getFileByID("#{file}".split('-')[0],'area51')
    .then((res) ->
      readFile(originFile)
      .then((originBuff) ->
        assert.equal(res.toString(),originBuff.toString())
      )
    )

  it 'should fails retrieving a file by ID, because there is no file matching this ID', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    weaverFileBrowser.getFileByID('f4k31d','area51')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should deletes a file by name', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    weaverFileBrowser.deleteFile("#{file}",'area51')
    .then( ->
      weaverFileBrowser.getFile("#{file}",'area51')
      .then((res) ->
        assert(false)
      ).catch((err) ->
        assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
      )
    )

  it 'should deletes a file by id', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    fileTemp = path.join(__dirname,'../icon.png')
    readFile(fileTemp)
    .then((file) ->
      weaverFileBrowser.saveFile(file, 'weaverIcon.png', 'area51').then((res) ->
        file = res
        assert.equal(res.split('-')[1],'weaverIcon.png')
        weaverFileBrowser.deleteFileByID("#{file}",'area51')
        .then( ->
          pathTemp = path.join(__dirname,'../tmp/weaver-icon.png')
          weaverFileBrowser.getFile("#{file}".split('-')[0],'area51')
          .then((res) ->
            assert(false)
          ).catch((err) ->
            assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
          )
        )
      )
    )


  it 'should fails trying to delete a file because the project does not exists', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    weaverFileBrowser.deleteFile("#{file}",'area69')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should fails trying to delete a file by ID because the project does not exists', ->
    weaverFileBrowser = new Weaver.FileBrowser()
    weaverFileBrowser.deleteFileByID("#{file}",'area69')
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code,Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )
