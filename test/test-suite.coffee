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
    signInAsAdmin()
  ).then(->
    weaver.wipe()
  ).then(->
    project = new Weaver.Project()
    project.create()
  ).then((project) ->
    weaver.useProject(project)
  )

ensureAdmin = ->
  if weaver.currentUser()?.userId isnt 'root'
    signInAsAdmin()
  else
    Promise.resolve()

signInAsAdmin = ->
  weaver.signInWithUsername('admin', 'admin')

beforeEach ->
  ensureAdmin()

after ->
  ensureAdmin().then(->
    weaver.wipe()
  ).then(->
    weaver.disconnect()
  )

# Previously ran before each test in each file
# NOTE THAT THIS BREAKS THE ACL ASSOCIATED WITH A PROJECT TESTING ON

wipeCurrentProject = ->
  ensureAdmin()
  .then(->weaver.getCoreManager().wipeUsers())
  .then(->weaver.currentProject().wipe())
  .then(->weaver.currentProject().unfreeze())

module.exports = { weaver, wipeCurrentProject, signInAsAdmin}
