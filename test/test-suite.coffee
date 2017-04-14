require("./globalize")
Weaver = require("../src/Weaver.coffee")
weaver = new Weaver()

# Runs before all tests (even across files)
before (done) ->
  weaver.connect(WEAVER_ENDPOINT)
  .then(->
    done()
  ).catch(console.log)
  return

# Runs after each test in each file
beforeEach (done) ->
  weaver.wipe()
  .then(->
    weaver.signInWithUsername('admin', 'admin')
  ).then(->
    project = new Weaver.Project()
    project.create()
  ).then((project) ->
    weaver.useProject(project)
    done()
  ).catch(console.log)
  return

afterEach ->
  weaver.wipe()

module.exports = weaver