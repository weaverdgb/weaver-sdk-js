$ = require("./../test-suite")()

# Weaver
Weaver = require('./../../src/weaver')
weaver = new Weaver()
weaver.connect(WEAVER_ADDRESS)

mohamad = null

beforeEach('clear repository', ->
  weaver.repository.clear()
)

describe 'Authentication', ->
  it 'should send a token', ->
    weaver.disconnect()
    weaver.channel = { authenticate: sinon.stub() };
    weaver.channel.authenticate.returns(Promise.resolve({ read: true, write: false}))

    promise = weaver.authenticate('test123')
    expect(weaver.channel.authenticate.callCount).to.equal(1)
    expect(weaver.channel.authenticate.firstCall.args[0]).to.equal('test123')
    promise.should.eventually.equal({ read: true, write: false })

    weaver.connect(WEAVER_ADDRESS)

describe 'Weaver: Creating entity', ->

  mohamad = weaver.add({name:'Mohamad Alamili', age: 28, isMale: true}, 'person')

  it 'should have all properties', ->
    mohamad.should.have.property('name')
    mohamad.name.should.equal('Mohamad Alamili')
    mohamad.age.should.equal(28)
    mohamad.isMale.should.be.true

  it 'should have property $', ->
    mohamad.should.have.property('$')

  it 'should be set as fetched', ->
    mohamad.$.fetched.should.be.true


describe 'Weaver: Linking entity', ->

  bastiaan = null

  it 'should link to another entity', ->
    bastiaan = weaver.add({name:'Bastiaan Bijl', age: 29}, 'human')
    mohamad.$push('friend', bastiaan)

    mohamad.should.have.property('friend')
    mohamad.friend.should.equal(bastiaan)


  gijs = null

  it 'should link to other entities as collection', ->
    gijs = weaver.add({name:'Gijs van der Ent', age: 35}, 'human')

    # TODO: make this a method
    friends = weaver.add({}, '_COLLECTION')
    friends.$push(bastiaan.$.id, bastiaan)
    friends.$push(gijs.$.id, gijs)
    mohamad.$push('friends', friends)
    bastiaan.$push('colleague', gijs)

    # EXP
    gijs.$push('buddy', mohamad)

    mohamad.should.have.property('friends')
    mohamad.friends.$values()[bastiaan.$id()].should.equal(bastiaan)
    mohamad.friends.$values()[gijs.$id()].should.equal(gijs)


describe 'Weaver: Loading entity', ->

  it 'should fetch from server lazy', ->
    id = mohamad.$.id
    #promise = weaver.get(id, {eagerness: -1})

    #promise.should.eventually.have.property('name')
    #promise.should.eventually.have.property('$')
    #promise.should.eventually.not.have.property('friends')

#    promise.then((mohamad) ->
#      #console.log(mohamad)
#      console.log(mohamad.$id())
#     # mohamad.name.should.equal('Mohamad Alamili')
#     # mohamad.$.fetched.should.be.false
#    )

  return
  it 'should fetch from server', ->
    id = mohamad.$.id
    promise = weaver.get(id, {eagerness: -1})

    promise.should.eventually.have.property('name')
    promise.should.eventually.have.property('$')
    promise.should.eventually.have.property('friends')

    promise.then((mohamad) ->
      mohamad.name.should.equal('Mohamad Alamili')
      mohamad.$.fetched.should.be.true

      mohamad.friends.values()[0].name.should.equal('Bastiaan Bijl')
      mohamad.friends.values()[1].name.should.equal('Gijs van der Ent')
    )

describe 'Weaver: addPromise', ->
  it 'should return a promise', ->
    returnValue = weaver.addPromise({ name: 'a test'})
    expect(returnValue).to.be.an.instanceof(Promise)

  it 'should reject on error', ->
    weaver.disconnect()
    weaver.addPromise({name: 'fail'}).should.be.rejected
    weaver.connect(WEAVER_ADDRESS)

describe 'Weaver: Creating an entity', ->

  it 'should set type as $ROOT if left empty', ->
    return

  it 'should set type if given', ->
    return

  it 'should generate a unique ID', ->
    return

  it 'should store a created entity in the repository', ->
    return

  it 'should allow for empty entities to be created', ->
    return

  it 'should allow for strings, numbers and booleans as keys', ->
    return

  it 'should give an error if an object or array is passed as a key', ->
    return

  it 'should give an error if entity already exists', ->
    return


describe 'Weaver: Loading an entity', ->

  it 'should not load an entity if already available in the repository', ->
    return

  it 'should load an entity if not available in the repository', ->
    return

  # TRICKY
  it 'should load an entity if available in the repository but eagerness is deeper than repository', ->
    return

  it 'should store a loaded entity in the repository', ->
    return

  it 'should store all loaded sub entities in the repository', ->
    return

  it 'should load with default eagerness set to 1 if unspecified', ->
    return

  it 'should load endlessly if eagerness is set to -1', ->
    return

  it 'should correctly load with eagerness level 2', ->
    return

  it 'should correctly load with eagerness level 3', ->
    return

  it 'should correctly load with eagerness level 4', ->
    return

  # TRICKY
  it 'should correctly load circular references within the entity', ->
    return

  # TRICKY
  it 'should attach already loaded entities from repository into newly loaded entity', ->
    return

  # TRICKY
  it 'should update references from already loaded entities from repository to the newly loaded entity', ->
    return

  # VERY TRICKY AND NOT YET POSSIBLE
  it 'should be able to fetch reverse relations', ->
    return
