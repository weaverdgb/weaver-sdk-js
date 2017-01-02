module.exports = ->

  beforeEach( ->
  )

  chai = require('chai')
  sinon = require('sinon')
  chaiAsPromised = require('chai-as-promised')

  # Init
  global.Promise = require('bluebird')


  chai.use(chaiAsPromised);
  # You need to call chai.should() before being able to wrap everything with should
  chai.should();

  # Make Chai global (within all tests)
  global.expect = chai.expect
  global.assert = chai.assert
  global.should = chai.should

  global.sinon = sinon

  # TODO: Use config
  global.WEAVER_ADDRESS = process.env.WEAVER_ADDRESS or 'http://localhost:9487'
  global.ADMIN_ADDRESS  = process.env.ADMIN_ADDRESS  or 'http://localhost:8500'


  global.wipe = ->
    # Weaver.getCoreManager().getCommController().GET(ADMIN_ADDRESS, 'wipe');