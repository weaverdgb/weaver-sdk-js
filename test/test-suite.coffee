require("./globalize")
Weaver = require("../src/Weaver.coffee")
weaver = new Weaver()

# Runs before all tests (even across files)
before ->
  options = {}
  if !WEAVER_REJECT_UNAUTHORIZED
    options.rejectUnauthorized = false
  weaver.connect(WEAVER_ENDPOINT,options).then(->
    weaver.wipe()
  ).then(->
    weaver.signInWithUsername('admin', 'admin')
  ).then(->
    project = new Weaver.Project()
    project.create()
  ).then((project) ->
    weaver.useProject(project)
  )

after ->
  weaver.wipe()

# Runs after each test in each file
beforeEach ->
  weaver.currentProject().wipe().then(->
    weaver.getCoreManager().wipeUsers()
  ).then(->
    weaver.signInWithUsername('admin', 'admin')
  )

module.exports = weaver
