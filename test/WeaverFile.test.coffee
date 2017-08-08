weaver = require("./test-suite")
Weaver = require('../src/Weaver')

path     = require('path')
Promise  = require('bluebird')
readFile = Promise.promisify(require('fs').readFile)

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

  it 'should deny access when uploading with unauthorized user', ->
    @timeout(15000)

    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')

    user = new Weaver.User("username", "password", "some@email.com")
    user.signUp()
    .then(->
      weaverFile.saveFile(fileTemp, 'weaverIcon.png')
    ).then(->
       assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should deny access when uploading with read-only user', ->
    @timeout(15000)

    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')

    user = new Weaver.User("username", "password", "some@email.com")
    user.create()
    .then(->
      weaver.currentProject().getACL()
    ).then((projectACL) ->
      projectACL.setUserReadAccess(user, true)
      projectACL.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername("username", "password")
    ).then(->
      weaverFile.saveFile(fileTemp, 'weaverIcon.png')
    ).then(->
       assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should allow access when uploading with authorized user with write permission', ->
    @timeout(15000)

    weaverFile = new Weaver.File()
    fileTemp = path.join(__dirname,'../icon.png')

    user = new Weaver.User("username", "password", "some@email.com")
    user.create()
    .then(->
      weaver.currentProject().getACL()
    ).then((projectACL) ->
      projectACL.setUserReadAccess(user, true)
      projectACL.setUserWriteAccess(user, true)
      projectACL.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername("username", "password")
    ).then(->
      weaverFile.saveFile(fileTemp, 'weaverIcon.png')
    ).then(->
      assert.isTrue(true)
    ).catch((err) ->
      console.log err
      assert.fail()
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

  describe 'with an uploaded file', ->
    beforeEach ->
      @timeout(15000)

      weaverFile = new Weaver.File()
      fileTemp = path.join(__dirname,'../icon.png')

      readOnly = new Weaver.User("readonly", "password", "some@email.com")
      noAccess = new Weaver.User("noAccess", "password", "some2@email.com")
      Promise.all([
        readOnly.create()
        noAccess.create()
      ]).then(->
        weaver.currentProject().getACL()
      ).then((projectACL) ->
        projectACL.setUserReadAccess(readOnly, true)
        projectACL.save()
      ).then(->
        weaverFile.saveFile(fileTemp, 'weaverIcon.png')
      ).then((r) ->
        @fileId = r
      )

    it 'should allow users with read permission access to attachments', ->
      weaver.signOut().then(-> weaver.signInWithUsername('readonly', 'password'))
      .then(-> new Weaver.File().getFileByID('./tmp/test-file', @fileId))
    
    it 'should not allow users without read permission access to attachments', ->
      weaver.signOut().then(-> weaver.signInWithUsername('noAccess', 'password'))
      .then(->
        expect( -> new Weaver.File().getFileByID('./tmp/test-file', @fileId)
        ).to.throw
      )
