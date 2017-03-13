require("./globalize")

Promise = require('bluebird')
project = null

createProject = ->
  project = new Weaver.Project()
  project.create().then(->
    Weaver.useProject(project)
  )

wipe = (systemWipe) ->
  return
  coreManager = Weaver.getCoreManager()
  Promise.all([
    coreManager.wipe("$SYSTEM") if systemWipe
    coreManager.wipe(project.id()) if project?
  ])

# Runs before all tests
before (done) ->

  Weaver.connect(WEAVER_ENDPOINT)
  .then(-> adminSignin())
  .then(-> Weaver.wipe())
  .then(-> adminSignin())
  .then(-> createProject())
  .then(-> done())
  .catch(console.log)
  return



# Runs after all tests
after (done) ->
  done()
  return
  project.destroy().then(->
    wipe(true)
  ).then(->
    done()
  )
  return

# Runs after each test
# Let the tests define this one?
afterEach ->
  return


# TODO: Full system clear of weaver server including projects and users
