weaver       = require("./test-suite").weaver
Weaver       = require('../src/Weaver')
stateManager = require('../src/WeaverStateManager.coffee')

describe 'WeaverReducer test', ->
  it 'should should create a reducer', ->


    bla = weaver.Node.get('bla')

    stateManager.addNode(bla)


    blaah = stateManager.getNode('bla')
    console.log(blaah)


    console.log('
    asdasdasdasdasdasd
    ')


    dee = weaver.Node.get('dee')
    bla.relation('link').add(dee)
    stateManager.addNode(bla)

    stateManager.addNode(dee)

    console.log(blaah)

    stateManager.addNode(weaver.Node.get('BLA!'))
