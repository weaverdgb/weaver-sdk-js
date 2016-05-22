require("./test-suite")()
fs = require('fs')
WeaverServer = require('weaver-server')
VirtuosoConnector  = require('weaver-connector-virtuoso')
WeaverCommons = require('weaver-commons-js')
Filter             = WeaverCommons.Filter
Promise = require('bluebird')

describe 'Create an object using Virtuoso connector', ->

  Weaver = null

  json = null


  before ->


    json = fs.readFileSync('./test/weaver/bas.json', 'utf8')          # todo make more dymamically powerful

    Weaver = require('./../../src/weaver')
    weaver = new Weaver()
    weaver.connect('http://localhost:9487')








  # for a description of the payload see
  # https://github.com/weaverplatform/weaverplatform/blob/master/weaver-sdk-payloads.md


  it 'Wipe', ->

    server.operations.wipe().should.be.fulfilled





  it 'Bootstrap', ->


    server.operations.bootstrapFromJson(json).should.be.fulfilled


  it 'Query for everything', ->

    filters = []

    Filter filter = new Filter('rdfs:label')
    filter.addValueCondition('any-value', '')



    filters.push(filter)

    memberIds = server.operations.queryFromFilters(filters)
    memberIds.then((res)->
      console.log(res)
    )
    memberIds.should.eventually.contain('cioirey6z000c3k6miexs76bq')    # mens
    memberIds.should.eventually.contain('cioirfiha000h3k6m6ju81fzo')    # aap
    memberIds.should.eventually.contain('cioirejcl00073k6ma5gmf1mv')    # dier
    memberIds.should.eventually.contain('cioirecea00023k6m3fl6ffm7')    # bastiaan


  it 'Query for all people', ->

    filters = []

    Filter filter = new Filter('rdf:type')
    filter.addIndividualCondition('this-individual', {id:'cioirey6z000c3k6miexs76bq'})



    filters.push(filter)

    memberIds = server.operations.queryFromFilters(filters)
    memberIds.then((res)->
      console.log(res)
    )
    memberIds.should.eventually.not.contain('cioirey6z000c3k6miexs76bq')    # mens
    memberIds.should.eventually.not.contain('cioirfiha000h3k6m6ju81fzo')    # aap
    memberIds.should.eventually.not.contain('cioirejcl00073k6ma5gmf1mv')    # dier
    memberIds.should.eventually.contain('cioirecea00023k6m3fl6ffm7')    # bastiaan


  it 'Query for class Dier by code', ->

    filters = []

    Filter filter = new Filter('ib:hasCode')
    filter.addValueCondition('this-value', 'a')



    filters.push(filter)

    memberIds = server.operations.queryFromFilters(filters)
    memberIds.then((res)->
      console.log(res)
    )
    memberIds.should.eventually.not.contain('cioirey6z000c3k6miexs76bq')    # mens
    memberIds.should.eventually.not.contain('cioirfiha000h3k6m6ju81fzo')    # aap
    memberIds.should.eventually.contain('cioirejcl00073k6ma5gmf1mv')    # dier
    memberIds.should.eventually.not.contain('cioirecea00023k6m3fl6ffm7')    # bastiaan



