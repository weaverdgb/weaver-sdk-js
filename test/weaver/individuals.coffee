require("../test-suite")()
fs = require('fs')
WeaverCommons = require('weaver-commons-js')
Filter             = WeaverCommons.Filter
Promise = require('bluebird')

describe 'Create an object using Virtuoso connector', ->

  weaver = null

  json = null


  before ->



    Weaver = require('./../../src/weaver')
    weaver = new Weaver()
    weaver.connect('http://192.168.99.100:9487')








  # for a description of the payload see
  # https://github.com/weaverplatform/weaverplatform/blob/master/weaver-sdk-payloads.md


  it 'Wipe', ->

    weaver.channel.wipe().should.be.fulfilled





  it 'Add individual with properties', ->


    object = weaver.add({name: 'Baaaaaa'}, '$INDIVIDUAL')
    object2 = weaver.add({name: 'Doooooo'}, '$INDIVIDUAL')


    # Create first property
    object.properties = weaver.collection()
    object.$push('properties')


    property = weaver.add({subject: object, predicate: 'rdfs:label', object: 'Unnamed'}, '$VALUE_PROPERTY')
    object.properties.$push(property)


#    property2 = weaver.add({subject: object, predicate: 'rdf:type', object: object2}, '$INDIVIDUAL_PROPERTY')
    property2 = weaver.add({subject: object, predicate: 'rara', object: object2}, '$INDIVIDUAL_PROPERTY')

    object.properties.$push(property2)


