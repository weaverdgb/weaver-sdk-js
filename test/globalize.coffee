# Libs
Promise      = require('bluebird')
config       = require('config')
chai         = require('chai')
sinon        = require('sinon')

# Use chai as promised
chai.use(require('chai-as-promised'))

# You need to call chai.should() before being able to wrap everything with should
chai.should()

# From libs
global.expect  = chai.expect
global.assert  = chai.assert
global.should  = chai.should
global.sinon   = sinon

# Configuration
global.WEAVER_ENDPOINT = if config.has('weaver.endpoint') then config.get("weaver.endpoint") else 'http://localhost:9487'
global.WEAVER_REJECT_UNAUTHORIZED = if config.has('weaver.rejectUnauthorized') then config.get("weaver.rejectUnauthorized") else false
