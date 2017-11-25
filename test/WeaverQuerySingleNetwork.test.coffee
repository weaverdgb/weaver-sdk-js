weaver = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver = require('../src/Weaver')

checkNodeInResult = (nodes, nodeId) ->
  ids = (i.id() for i in nodes)
  expect(ids).to.contain(nodeId)

describe 'WeaverQuery with single Network', ->
  tree             = new Weaver.Node()
  garden           = new Weaver.Node()
  ferrari          = new Weaver.Node()
  car              = new Weaver.Node()
  motorizedVehicle = new Weaver.Node()
  wheel            = new Weaver.Node()
  pirelli          = new Weaver.Node()
  vettel           = new Weaver.Node()
  hamilton         = new Weaver.Node()

  tree.set('testset', '1')

  garden.relation('requires').add(tree)
  garden.set('name', 'backyard')
  garden.set('theme', 'forest')
  garden.set('testset', '1')

  ferrari.set('description', 'Fast, red')
  ferrari.set('could-be-electric', 'maybe-hybrid')
  ferrari.set('testset', '2')

  car.set('description', 'Thing with wheels')
  car.set('objectiveValue', '12')
  car.set('testset', '2')

  motorizedVehicle.set('description', 'Poweeeerrrrr')
  motorizedVehicle.set('could-be-electric', 'sure')
  motorizedVehicle.set('testset', '2')

  ferrari.relation('is-a').add(car)
  car.relation('is-a').add(motorizedVehicle)

  wheel.set('testset', '2')
  pirelli.set('testset', '2')

  pirelli.relation('is-brand-of').add(wheel)
  ferrari.relation('hasTires').add(pirelli)

  vettel.set('testset', '2')
  vettel.relation('drives').add(ferrari)

  hamilton.set('testset', '2')
  vettel.relation('beats').add(hamilton)
  hamilton.relation('beats').add(vettel)

  before ->
    wipeCurrentProject().then( ->
      Promise.all([vettel.save(), garden.save()])
    )

  it 'should support wildcard with nested Weaver.Query values', ->
    # Get all nodes which have any relation in from a node that is-a car
    new Weaver.Query()
    .hasRelationIn('*', new Weaver.Query().hasRelationOut('is-a', car))
    .find().then((nodes) ->
      expect(i.id() for i in nodes).to.eql([ car.id(), pirelli.id() ])
    )

  it 'should support wildcard relation hasRelationOut', ->
    new Weaver.Query()
    .hasRelationOut("*", tree)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )

  it 'should support wildcard relation hasRelationIn', ->
    new Weaver.Query()
    .hasRelationIn("*", garden)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support wildcard relation hasNoRelationOut', ->
    new Weaver.Query()
    .equalTo('testset', '1')
    .hasNoRelationOut("*", tree)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, tree.id())
    )

  it 'should support wildcard relation hasNoRelationIn', ->
    new Weaver.Query()
    .equalTo('testset', '1')
    .hasNoRelationIn("*", garden)
    .find().then((nodes) ->
      expect(nodes).to.have.length.be(1)
      checkNodeInResult(nodes, garden.id())
    )

  it 'should support find() after count()', ->
    q = new Weaver.Query().equalTo('testset', '1')

    q.count().should.eventually.equal(2).then(->
      q.find().should.eventually.have.length.be(2)
    )

  it 'should allow the selecting of attributes', ->
    new Weaver.Query()
    .equalTo('theme', 'forest')
    .select('name').find().then((result) ->
      expect(result).to.have.length.be(1)
      expect(result[0]).to.have.property('_attributes').to.have.property('name')
      expect(result[0]).to.have.property('_attributes').to.not.have.property('theme')
    )

  it 'should extend selects to selectOut nodes', ->
    new Weaver.Query()
    .restrict(ferrari.id())
    .select('description')
    .selectOut('is-a').find().then((result)->
      expect(result).to.have.length.be(1)
      expect(result[0]).to.have.property('_loaded').equal(false)
      expect(result[0]).to.have.property('_relations').to.have.property('is-a')
      types = result[0]._relations['is-a'].all()
      expect(types).to.have.length.be(1)
      expect(types[0]).to.have.property('_loaded').equal(false)
      expect(types[0]).to.have.property('_attributes').to.have.property('description')
      expect(types[0]).to.have.property('_attributes').to.not.have.property('objectiveValue')
    )

  it 'should extend selects to recursive select out nodes', ->
    new Weaver.Query()
    .restrict(ferrari.id())
    .select('description')
    .selectRecursiveOut('is-a').find().then((result)->
      expect(result).to.have.length.be(1)
      expect(result[0]).to.have.property('_loaded').equal(false)
      expect(result[0]).to.have.property('_relations').to.have.property('is-a')
      types = result[0]._relations['is-a'].all()
      expect(types).to.have.length.be(1)
      expect(types[0]).to.have.property('_loaded').equal(false)
      expect(types[0]).to.have.property('_attributes').to.have.property('description')
      expect(types[0]).to.have.property('_attributes').to.not.have.property('objectiveValue')
      expect(types[0]).to.have.property('_relations').to.have.property('is-a')
      parentTypes = result[0]._relations['is-a'].all()
      expect(parentTypes).to.have.length.be(1)
      expect(parentTypes[0]).to.have.property('_loaded').equal(false)
      expect(parentTypes[0]).to.have.property('_attributes').to.have.property('description')
      expect(parentTypes[0]).to.have.property('_attributes').to.not.have.property('could-be-electric')
    )

  it 'should mark nodes loaded with a select as non-loaded', ->
    new Weaver.Query().restrict(ferrari.id()).select('description').find().then((res) ->
      expect(res[0]).to.have.property('_loaded').equal(false)
    )

  it 'should mark nodes loaded without a select as loaded', ->
    new Weaver.Query().restrict(ferrari.id()).find().then((res) ->
      expect(res[0]).to.have.property('_loaded').equal(true)
    )

  it 'should mark nodes not loaded nodes as non-loaded', ->
    new Weaver.Query().restrict(ferrari.id()).find().then((res) ->
      expect(res[0]._relations['is-a'].all()[0]).to.have.property('_loaded').equal(false)
    )

  it 'should mark selectOut nodes loaded without a select as loaded', ->
    new Weaver.Query().restrict(ferrari.id()).selectOut('is-a').find().then((res) ->
      loadedCar = res[0]._relations['is-a'].all()[0]
      expect(loadedCar).to.have.property('_loaded').to.equal(true)
    )

  it 'should mark selectRecursiveOut nodes loaded without a select as loaded', ->
    new Weaver.Query().restrict(ferrari.id()).selectRecursiveOut('is-a').find().then((res) ->
      loadedCar = res[0]._relations['is-a'].all()[0]
      expect(loadedCar).to.have.property('_loaded').to.equal(true)
      loadedMotorizedVehicle = loadedCar._relations['is-a'].all()[0]
      expect(loadedMotorizedVehicle).to.have.property('_loaded').to.equal(true)
    )

  it 'should allow for contains on the id property', ->
    new Weaver.Query().contains('id', tree.id()).find().then((res) ->
      expect(res).to.have.length.be(1)
      expect(res[0].id()).to.equal(tree.id())
    )

  it 'should support always including a relation of non-loaded relations', ->
    new Weaver.Query().alwaysLoadRelations('is-brand-of').restrict(ferrari.id()).find().then((nodes) ->
      expect(i.id() for i in nodes).to.eql([ferrari.id()])
      expect(nodes[0])
      .to.have.property('_relations')
      .to.have.property('hasTires')
      .to.have.property('nodes')
      .to.have.property(pirelli.id())
      .to.have.property('_relations')
      .to.have.property('is-brand-of')
      .to.have.property('nodes')
      .to.have.property(wheel.id())
    )

  it 'should support selectOut always including a relation of non-loaded relations', ->
    new Weaver.Query().selectOut('drives').alwaysLoadRelations('is-brand-of').restrict(vettel.id()).find().then((nodes) ->
      expect(i.id() for i in nodes).to.eql([vettel.id()])
      expect(nodes[0])
      .to.have.property('_relations')
      .to.have.property('drives')
      .to.have.property('nodes')
      .to.have.property(ferrari.id())
      .to.have.property('_relations')
      .to.have.property('hasTires')
      .to.have.property('nodes')
      .to.have.property(pirelli.id())
      .to.have.property('_relations')
      .to.have.property('is-brand-of')
      .to.have.property('nodes')
      .to.have.property(wheel.id())
    )

  it 'should allow hasRecursiveRelationOut not including self', ->
    new Weaver.Query().hasRecursiveRelationOut('is-a', motorizedVehicle.id()).find().then((nodes) ->
      expect(i.id() for i in nodes).to.have.members([ car.id(), ferrari.id()])
    )
  
  it 'should allow hasRecursiveRelationOut including self', ->
    new Weaver.Query().hasRecursiveRelationOut('is-a', motorizedVehicle, true).find().then((nodes) ->
      expect(i.id() for i in nodes).to.have.members([ car.id(), ferrari.id(), motorizedVehicle.id()])
    )
    
  it 'should allow hasRecursiveRelationIn not including self', ->
    new Weaver.Query().hasRecursiveRelationIn('is-a', ferrari.id()).find().then((nodes) ->
      expect(i.id() for i in nodes).to.have.members([ car.id(), motorizedVehicle.id()])
    )
  
  it 'should allow hasRecursiveRelationIn including self', ->
    new Weaver.Query().hasRecursiveRelationIn('is-a', ferrari, true).find().then((nodes) ->
      expect(i.id() for i in nodes).to.have.members([ car.id(), ferrari.id(), motorizedVehicle.id()])
    )

  it 'should allow hasNoRecursiveRelationOut not including self', ->
    new Weaver.Query()
    .equalTo('testset', '2')
    .hasNoRecursiveRelationOut('is-a', motorizedVehicle.id())
    .find().then((nodes) ->
      expect(i.id() for i in nodes).to.not.have.members([ ferrari.id(), car.id() ])
    )
  
  it 'should allow hasNoRecursiveRelationOut including self', ->
    new Weaver.Query()
    .equalTo('testset', '2')
    .hasNoRecursiveRelationOut('is-a', motorizedVehicle, true)
    .find().then((nodes) ->
      expect(i.id() for i in nodes).to.not.have.members([ motorizedVehicle.id(), ferrari.id(), car.id() ])
    )
  
  it 'should allow hasNoRecursiveRelationIn not including self', ->
    new Weaver.Query()
    .equalTo('testset', '2')
    .hasNoRecursiveRelationIn('is-a', ferrari.id())
    .find().then((nodes) ->
      expect(i.id() for i in nodes).to.not.have.members([ motorizedVehicle.id(), car.id() ])
    )
  
  it 'should allow hasNoRecursiveRelationIn including self', ->
    new Weaver.Query()
    .equalTo('testset', '2')
    .hasNoRecursiveRelationIn('is-a', ferrari, true)
    .find().then((nodes) ->
      expect(i.id() for i in nodes).to.not.have.members([ motorizedVehicle.id(), ferrari.id(), car.id() ])
    )
