require("./test-suite")
supertest = require('supertest')
should    = require('should')
config    = require('config')

Weaver = require('./../src/Weaver')

weaverServer = supertest.agent(config.get("weaver.endpoint"))

describe 'Weaver REST API test', ->
  
  it 'should get the weaver-server version', ->
    weaverServer
    .get('/application/version')
    .expect("Content-type",/text/)
    .expect(200)
    .then((res, err) ->
      res.status.should.equal(200)
      res.text.should.equal('2.1.4-beta0')
    )