weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

path     = require('path')
fs       = require('fs')
Promise  = require('bluebird')
readFile = Promise.promisify(require('fs').readFile)

describe 'WeaverFile test', ->
  user = null
  before ->
    wipeCurrentProject()

  it 'should create a new file', ->
    @timeout(15000) # This timeout is high because the 1st time minio takes more time (extra time creating a bucket)

    file = new Weaver.File(path.join(__dirname,'../icon.png'))
    file.upload()
    .then((storedFile) ->
      assert.isTrue(file._stored)
      assert.equal(storedFile.name(), file.name())
    )

  it 'should get filestats when setting the path', ->
    file = new Weaver.File()
    file.setPath(path.join(__dirname, '../icon.png'))
    expect(file.path()).to.equal(path.join(__dirname, '../icon.png'))
    expect(file._local).to.be.true

  it 'should get filestats when setting the path', ->
    file = new Weaver.File()
    file.setPath(path.join(__dirname, '../icon.png'))
    expect(file.path()).to.equal(path.join(__dirname, '../icon.png'))
    expect(file.size()).to.be.not.undefined
    expect(file._local).to.be.true

  it 'should not read any filestats if file doesn\'t exist', ->
    file = new Weaver.File()
    file.setPath(path.join(__dirname, '../foo.bar'))
    expect(file.path()).to.be.undefined
    expect(file.size()).to.be.undefined
    expect(file._local).to.be.false

  it 'should create a new file, list it and then download it', ->
    @timeout(15000)

    file = new Weaver.File(path.join(__dirname, '../icon.png'))
    assert.isFalse(file._stored)

    file.upload().then((storedFile) ->
      assert.isTrue(file._stored)
      assert.equal(storedFile.name(), file.name())

      Weaver.File.list()
    ).then((files) ->
      expect(files.length).to.be.at.least(1)
      Weaver.File.get(file.id()).download("clone-#{file.name()}")
    ).then((downloadedFile) ->
      new Promise((resolve, reject) ->
        fs.stat(downloadedFile.path(), (err, file) ->
          fs.unlink(downloadedFile.path(), ->
            resolve() if not err?
          )
        )
      )
    )

  it 'should list files', ->
    file = new Weaver.File(path.join(__dirname, '../icon.png'))
    assert.isFalse(file._stored)

    file.upload().then((storedFile) ->
      assert.isTrue(file._stored)
      assert.equal(storedFile.name(), file.name())

      Weaver.File.list()
    ).then((files) ->
      expect(files.length).to.be.at.least(1)
    )

  it 'should support simultanious upload', ->
    @timeout(15000)
    file = new Weaver.File(path.join(__dirname,'../icon.png'))
    file2 = new Weaver.File(path.join(__dirname,'../icon.png'))

    #Make sure bucket exists
    Weaver.File.list().then(->
      Promise.all([file.upload(), file2.upload()])
    ).then((storedFiles) ->
      expect(storedFiles.length).to.equal(2)
    )


  it 'should deny access when uploading with unauthorized user', ->
    @timeout(15000)

    file = new Weaver.File(path.join(__dirname,'../icon.png'))

    user = new Weaver.User("username", "password", "some@email.com")
    user.signUp()
    .then(->
      file.upload()
    ).then(->
       assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should deny access when uploading with read-only user', ->
    @timeout(15000)

    file = new Weaver.File(path.join(__dirname,'../icon.png'))

    weaver.currentProject().getACL()
    .then((projectACL) ->
      projectACL.setUserReadAccess(user, true)
      projectACL.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername("username", "password")
    ).then(->
      file.upload()
    ).then(->
       assert.fail()
    ).catch((err) ->
      expect(err).to.have.property('message').match(/Permission denied/)
    )

  it 'should allow access when uploading with authorized user with write permission', ->
    @timeout(15000)

    file = new Weaver.File(path.join(__dirname,'../icon.png'))

    weaver.currentProject().getACL()
    .then((projectACL) ->
      projectACL.setUserReadAccess(user, true)
      projectACL.setUserWriteAccess(user, true)
      projectACL.save()
    ).then(->
      weaver.signOut()
    ).then(->
      weaver.signInWithUsername("username", "password")
    ).then(->
      file.upload()
    ).then(->
      assert.isTrue(true)
    ).catch((err) ->
      assert.fail()
    )

  it 'should fail creating a new file, because the file does not exists on local machine', ->
    file = new Weaver.File('../foo.bar')
    file.upload()
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert.equal(err.code, Weaver.Error.FILE_NOT_EXISTS_ERROR)
    )

  it 'should fail retrieving a file, because the file does not exits on server', ->
    file = Weaver.File.get('some-random-file')
    file.download(path.join(__dirname,'../tmp/weaver-icon.png'))
    .then((res) ->
      assert(false)
    ).catch((err) ->
      assert(true)
    )

  it 'should retrieve a file by ID', ->
    @timeout(15000)

    file = new Weaver.File(path.join(__dirname,'../icon.png'))

    file.upload()
    .then((storedFile) ->
      Weaver.File.get(storedFile.id()).download("clone-#{storedFile.name()}")
    ).then((downloadedFile) ->
      readFile(downloadedFile.path())
    ).then((destBuff) ->
      readFile(file.path())
      .then((originBuff) ->
        assert.equal(destBuff.toString(),originBuff.toString())
      )
    )

  it 'should delete a file by id', ->
    @timeout(30000)
    file = new Weaver.File(path.join(__dirname,'../icon.png'))
    file.upload()
    .then((storedFile) ->
      assert.equal(storedFile.name(), file.name())
      storedFile.destroy()
    ).then( ->
      Weaver.File.get(file.id()).download('./icon.png')
      .then((res) ->
        assert(false)
      ).catch((err) ->
        assert(true)
      )
    )

  describe 'with an uploaded file', ->
    before ->
      @timeout(15000)

      file = new Weaver.File(path.join(__dirname,'../icon.png'))

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
        file.upload()
      ).then((storedFile) ->
        @fileId = storedFile.id()
      )

    it 'should allow users with read permission access to attachments', ->
      weaver.signOut().then(-> weaver.signInWithUsername('readonly', 'password'))
      .then(-> Weaver.File.get(@fileId).download('./tmp/test-file'))

    it 'should not allow users without read permission access to attachments', ->
      weaver.signOut()
      .then(-> weaver.signInWithUsername('noAccess', 'password'))
      .then(->
        expect(->
          Weaver.File.get(@fileId).download('./tmp/test-file')
        ).to.throw
      )

  describe 'with listed files', ->
    file = null
    beforeEach ->
      @timeout(15000)

      file = new Weaver.File(path.join(__dirname,'../icon.png'))
      file.upload()

    it 'should get the filename', ->
      Weaver.File.list().then((files) ->
        f = files[files.length - 1] # Get the last uploaded file
        expect(f.name()).to.equal(file.name())
      )

    it 'should get the extension', ->
      Weaver.File.list().then((files) ->
        f = files[files.length - 1] # Get the last uploaded file
        expect(f.extension()).to.equal(file.extension())
      )

    it 'should get the filesize', ->
      Weaver.File.list().then((files) ->
        f = files[files.length - 1] # Get the last uploaded file
        expect(f.size()).to.equal(file.size())
      )
