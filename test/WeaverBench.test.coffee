weaver  = require("./test-suite").weaver
cuid    = require('cuid')
Weaver  = require('../src/Weaver')
Promise = require('bluebird')

describe 'WeaverBench Test', ->


  it 'should upated with onlyTo', ->
    node = new Weaver.Node()
    a = new Weaver.Node()
    b = new Weaver.Node()
    c = new Weaver.Node()
    d = new Weaver.Node()

    Weaver.Bench.do.onlyTo(node, 'link', a)



 