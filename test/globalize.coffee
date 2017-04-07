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

weaver = new Weaver()

# From libs
global.Promise = Promise
global.weaver  = weaver
global.Weaver  = weaver.getClass()
global.cuid    = cuid
global.expect  = chai.expect
global.assert  = chai.assert
global.should  = chai.should
global.sinon   = sinon

# Configuration
global.WEAVER_ENDPOINT = config.get("weaver.endpoint")
