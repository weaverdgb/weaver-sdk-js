weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')
cuid   = require('cuid')

describe 'NodeSynchronizer test', ->

  it 'should', (done) ->
    a1 = new Weaver.Node("a")
    a1.sync()
    a2 = new Weaver.Node("a")
    a2.sync()
    a3 = new Weaver.Node("a")
    a3.sync()
    b1 = new Weaver.Node("b")
    b1.sync()

    [a1, a2, a3, b1].map((n) -> n.sync())

    a1.set('name', 'John')
    a2.set('age', 16)
    a1.release()
    setTimeout((->
      a2.unset('age')

    ), 100)

    setTimeout((->
      console.log a2.get('name')
      console.log b1.get('name')
      console.log a1.get('age')

      done()
    ), 200)
