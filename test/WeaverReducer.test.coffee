weaver       = require("./test-suite").weaver
Weaver       = require('../src/Weaver')
stateManager = require('../src/WeaverStateManager.coffee')

describe 'WeaverReducer test', ->
  it 'should should create a reducer', ->


    bla = weaver.Node.get('bla')
    bLA = weaver.Node.get('BLA!')
    blaah = weaver.Node.get('blaah')
    bla.set('name', 'bla')

    bla.set('name', 'test')
    bla.set('name', 'test1')
    bla.set('name', 'test2')

    dee = weaver.Node.get('dee')
    bla.relation('link').add(dee)
    bla.relation('link').add(dee)
    bla.relation('link').add(bLA)


    console.log(JSON.stringify(weaver.stateManager.repository,null,2))
