weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'Database Test', ->

  it 'should clean the database', ->
    cm = Weaver.getCoreManager()
    r1 = []
    r2 = []
    q = new Weaver.Query()

    a = new Weaver.Node("a")
    b = new Weaver.Node("b")
    c = new Weaver.Node("c")
    d = new Weaver.Node("d")
    e = new Weaver.Node("e")

    a.set('age', 24)
    b.relation('knows').add(c)
    c.relation('knows').add(d)
    d.set('name', 'john')

    Weaver.Node.batchSave([a,b,c,d,e]).then(() ->
      a.set('age', 25)
      d.set('name', 'John')
      c.relation('knows').update(d, e)
      Promise.all([a.save(), c.save(), d.save()])
    ).then(->
      a.destroy()
      b.destroy()
    ).then(->
      cm.cleanup()
    ).then(->
      q.nativeQuery("SELECT * FROM nodes")
    ).then((results)->
      r1 = results
    ).then(->
      q.nativeQuery(
        "SELECT * FROM nodes n
         WHERE NOT (EXISTS (SELECT 1 FROM removed_nodes WHERE removed_nodes.removed_node = n.id LIMIT 1))
         AND NOT (EXISTS (SELECT 1 FROM removed_nodes WHERE removed_nodes.node = n.id LIMIT 1))
         AND NOT (EXISTS (SELECT 1 FROM replaced_attributes WHERE replaced_attributes.node = n.id LIMIT 1))
         AND NOT (EXISTS (SELECT 1 FROM replaced_relations WHERE replaced_relations.node = n.id LIMIT 1))"
      )
    ).then((results)->
      r2 = results

      i = 0
      j = 0

      while i < r2.length && j < r1.length
        console.log r2[i]
        console.log r1[j]
        console.log ""

        if r2[i].id == r1[j].id
          j++
          i++
        else if r2[i].id > r1[j].id
          j++
        else
          i++

      while j < r1.length
        console.log r1[j]
        j++

      while i < r2.length
        console.log r2[i]
        i++

    ).then(->
      # expect(r1).to.equal(r2)
      expect(r1.length).to.equal(r2.length)
    )
