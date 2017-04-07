require("./globalize")


# Runs before all tests (even across files)
before (done) ->
  weaver.connect(WEAVER_ENDPOINT)
  .then(-> done())
  .catch(console.log)
  return

# Runs after each test in each file
beforeEach (done) ->
  weaver.wipe()
  .then(->
    weaver.signIn('admin', 'admin')
  )
  .then(->
    new Weaver.Project().create()
  )
  .then((project) ->
    weaver.useProject(project)
    done()
  )
  .catch(console.log)
  return
