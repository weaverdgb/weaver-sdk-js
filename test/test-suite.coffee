require("./globalize")
Weaver = require("../src/Weaver.coffee")
weaver = new Weaver()

# Runs before all tests (even across files)
before ->
  options = {}
  if !WEAVER_REJECT_UNAUTHORIZED
    options.rejectUnauthorized = false
  weaver.connect(WEAVER_ENDPOINT,options)
  .then(->
    weaver.signInWithUsername('admin', 'admin')
  ).then(->
    weaver.wipe()
  ).then(->
    project = new Weaver.Project()
    project.create()
  ).then((project) ->
    weaver.useProject(project)
  )

after ->
  weaver.signInWithUsername('admin', 'admin')
  .then(->
    weaver.wipe()
  )

# Runs after each test in each file
# NOTE THAT THIS BREAKS THE ACL ASSOCIATED WITH A PROJECT TESTING ON

beforeEach ->
  weaver.signInWithUsername('admin', 'admin')
  .then(->weaver.getCoreManager().wipeUsers())
  .then(->weaver.currentProject().wipe())

module.exports = weaver
