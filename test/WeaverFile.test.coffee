require("./test-suite")

describe 'WeaverFile test', ->

  it 'should create a new file by base64', ->
    base64 = "V2VhdmVyIGlzIEF3ZXNvbWUh"
    weaverFile = new Weaver.File()
    weaverFile.setBase64(base64)
    weaverFile.save()

  it 'should create a new file by an upload form', ->
    fileUploadControl = $("#fileUpload")[0]
    if fileUploadControl.files.length > 0
      file = fileUploadControl.files[0]
      weaverFile = new Weaver.File(file)
      weaverFile.setFile(file)
      weaverFile.save()

  # Later this URL will contain some form of session to authorize with
  it 'should load a file by URL'
    weaverFile = new Weaver.File()
    weaverFile.setBase64("V2VhdmVyIGlzIEF3ZXNvbWUh")
    weaverFile.save().then(->

      # Assert URL
      expect(weaverFile.url()).to.be.defined

      Weaver.File.load(weaverFile.id())
    ).then((loadedFile) ->
      expect(loadedFile.url()).to.be.defined

      # Would be cool to somehow test that the file behind the URL is actually the encoded string
    )
