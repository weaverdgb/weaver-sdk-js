require("./globalize")


# Runs before all tests
before (done) ->

  Weaver.connect(WEAVER_ENDPOINT)
  .then(->
    Weaver.wipe()
  )
  .then(->
    Weaver.signIn('admin', 'admin')
  )
  .then(->
    project = new Weaver.Project()
    project.create()
  )
  .then((project) ->
    Weaver.useProject(project)
    done()
  )
  .catch(console.log)
  return
