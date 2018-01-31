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

signInAsAdmin = ->
  weaver.signInWithUsername('admin', 'admin')

beforeEach ->
  if weaver.currentUser()?.userId isnt 'root'
    signInAsAdmin()

after ->
  (
    if weaver.currentUser()?.userId isnt 'root'
      signInAsAdmin()
    else
      Promise.resolve()
  ).then(->
    weaver.wipe()
  ).then(->
    weaver.disconnect()
  )

# Previously ran before each test in each file
# NOTE THAT THIS BREAKS THE ACL ASSOCIATED WITH A PROJECT TESTING ON

wipeCurrentProject = ->
  weaver.signInWithUsername('admin', 'admin')
  .then(->weaver.getCoreManager().wipeUsers())
  .then(->weaver.currentProject().wipe())
  .then(->weaver.currentProject().unfreeze())

module.exports = { weaver, wipeCurrentProject, signInAsAdmin}
