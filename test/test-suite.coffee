require("./globalize")

# Runs before all tests (even across files)
before (done) ->
  Weaver.connect(WEAVER_ENDPOINT).then(-> done())
  return

# Runs after each test in each file
beforeEach (done) ->
  Weaver.wipe()
  .then(->
    Weaver.signInWithUsername('admin', 'admin')
  )
  .then(->
    new Weaver.Project().create()
  )
  .then((project) ->
    Weaver.useProject(project)
    done()
  )
  .catch(console.log)
  return
