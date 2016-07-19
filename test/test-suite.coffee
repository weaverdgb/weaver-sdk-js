module.exports = ->

  beforeEach( ->
  )

  # Init
  global.Promise = require('bluebird')
  chai = require('chai')
  sinon = require('sinon')
  chaiAsPromised = require('chai-as-promised')

  chai.use(chaiAsPromised);
  # You need to call chai.should() before being able to wrap everything with should
  chai.should(); 
  
  # Make Chai global (within all tests)
  global.expect = chai.expect
  global.assert = chai.assert
  global.should = chai.should

  global.WEAVER_ADDRESS = process.env.WEAVER_ADDRESS or 'http://192.168.99.100:9487'
