weaver       = require("./test-suite").weaver
Weaver       = require('../src/Weaver')
stateManager = weaver.getStateManager()

describe 'WeaverReducer test', ->
  it 'should should create a reducer', ->

    b = new Weaver.Node('bla')
    blaah = new Weaver.Node('blaah')
    b.set('name', 'name')
    # console.log(JSON.stringify(weaver.stateManager.repository,null,2))
    .relation('link').add(blaah).save().then(->
      stateManager.wipeStore()
      # console.log('&')
      # console.log(JSON.stringify(weaver.stateManager.repository,null,2))
      weaver.Node.load('bla')
    ).then((res)->
      console.log(JSON.stringify(weaver.stateManager.repository,null,2))
    ).catch(console.log)
    # bLA = weaver.Node.get('BLA!')
    # blaah = weaver.Node.get('blaah')
    # bla.set('name', 'bla')
    #
    # bla.set('name', 'test')
    # bla.set('name', 'test1')
    # bla.set('name', 'test2')
    #
    # dee = weaver.Node.get('dee')
    # bla.relation('link').add(dee)
    # bla.relation('link').add(dee)
    # bla.relation('link').add(bLA)
