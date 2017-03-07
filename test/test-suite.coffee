# Libs
Promise      = require('bluebird')
config       = require('config')
cuid         = require('cuid')
chai         = require('chai')
sinon        = require('sinon')
Weaver       = require('../src/Weaver')

# Use chai as promised
chai.use(require('chai-as-promised'));

# You need to call chai.should() before being able to wrap everything with should
chai.should();

# Expose global fields (within all tests)
global.Promise = Promise
global.Weaver  = Weaver
global.cuid    = cuid
global.expect  = chai.expect
global.assert  = chai.assert
global.should  = chai.should
global.sinon   = sinon

# Local vars
project = null
WEAVER_ENDPOINT = config.get("weaver.endpoint")

global.adminSignin = ->
  Weaver.signIn('admin', 'admin')

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
