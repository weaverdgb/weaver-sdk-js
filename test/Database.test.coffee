weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'Database Test', ->

  # Native query usage in this query can be replaced with a get all 'dirty nodes (select * from nodes)'
  # and get all 'clean nodes (select * from live_nodes)', comparing these should give a true
  it 'should clean the database', ->
    cm = Weaver.getCoreManager()
    allNodes = []
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
    ).then((nodes)->
      allNodes = nodes
    ).then(->
      q.nativeQuery(
        "SELECT * FROM nodes n
         WHERE NOT (EXISTS (SELECT 1 FROM removed_nodes WHERE removed_nodes.removed_node = n.id LIMIT 1))
         AND NOT (EXISTS (SELECT 1 FROM removed_nodes WHERE removed_nodes.node = n.id LIMIT 1))
         AND NOT (EXISTS (SELECT 1 FROM replaced_attributes WHERE replaced_attributes.node = n.id LIMIT 1))
         AND NOT (EXISTS (SELECT 1 FROM replaced_relations WHERE replaced_relations.node = n.id LIMIT 1))"
      )
    ).then((cleanNodes)->
      expect(allNodes).to.deep.equal(cleanNodes)
    )
