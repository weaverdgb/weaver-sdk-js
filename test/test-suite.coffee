require("./globalize")
Weaver = require("../src/Weaver.coffee")
weaver = new Weaver()

# Runs before all tests (even across files)
before ->
  weaver.connect(WEAVER_ENDPOINT).then(->
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
  weaver.signInWithUsername('admin', 'admin').then(->
    weaver.currentProject().wipe()
  )

module.exports = weaver
