require("./test-suite")

describe 'WeaverModel test', ->


  it 'should create a new node', ->

    something = new Weaver.Model()

    something.define("{}")

    helloWorld = something.instance()

    helloWorld.save().then( (res)->
      assert.isDefined(res[0].nodeId)
    )

  it 'should create a new node, with a specified id', ->

    something = new Weaver.Model()

    something.define("(chaise_lounge){}")

    helloWorld = something.instance()

    helloWorld.save().then( (res)->
      assert.equal(res[0].nodeId, 'chaise_lounge')
    )

  it 'should create a new node with a static attribute', ->

    something = new Weaver.Model()

    something.define("{
      <hasName>(John Doe)
    }")

    something = something.instance()



    something.save().then( (res)->
      assert.equal(res[0].attributes.hasName, 'John Doe')
    )

  it 'should create a new node with a dynamic attribute', ->

    something = new Weaver.Model()

    something.define("{
      <hasName>($name)
    }")

    hal = something.instance()

    hal.set('$name', 'H.A.L.')

    hal.save().then( (res)->
      assert.equal(res[0].attributes.hasName, 'H.A.L.')
    )

  it 'should create a new node with a relation', ->

    something = new Weaver.Model()

    something.define("{
      wasBuiltOn
    }")

    hal = something.instance()

    hal.save().then( (res)->
      assert.isDefined(res[0].relation('wasBuiltOn'))
    )

  it 'should create a new node with a static relation', ->

    new Weaver.Node('unknown').save().then(->

      mysteriousRelic = new Weaver.Model()

      mysteriousRelic.define("{
        wasFoundAt(unknown)
      }")

      magicRing = mysteriousRelic.instance()

      magicRing.save().then( (res)->
        assert.isDefined(res[0].relation('wasFoundAt').nodes['unknown'])
      )
    )

  it 'should create a new node with a dynamic relation', ->

    new Weaver.Node('Valhalla').save().then(->

      respectableViking = new Weaver.Model()

      respectableViking.define("{
        spendsAfterlifeIn($heaven)
      }")

      thomund = respectableViking.instance()

      thomund.add('$heaven', 'Valhalla')

      thomund.save().then( (res)->
        assert.isDefined(res[0].relation('spendsAfterlifeIn').nodes['Valhalla'])
      )
    )

  it 'should allow for nested relationships', ->

    family = new Weaver.Model()

    family.define("{
      <hasName>($grandParent)
      hasChild {
        <hasName>($parent)
        hasChild{
          <hasName>($child)
        }
      }
    }")

    theAddams = family.instance()

    theAddams.set('$grandParent', 'Grandpa Slurk')
    theAddams.set('$parent', 'Father Murk')
    theAddams.set('$child', 'Little Durk')

    theAddams.save().then( (res)->

      grandpa = res[0]
      parent = prop for key,prop of grandpa.relation('hasChild').nodes
      child = prop for key,prop of parent.relation('hasChild').nodes

      assert.equal(grandpa.attributes.hasName, 'Grandpa Slurk')
      assert.equal(parent.attributes.hasName, 'Father Murk')
      assert.equal(child.attributes.hasName, 'Little Durk')
    )

  it 'shouldn\'t instantiate a model instance when there are unset input fields', ->

    smurf = new Weaver.Model()

    smurf.define("{
      <hasName>($name)
    }")

    grumpy = smurf.instance()

    grumpy.save().catch( (err)->
      assert.equal(err.message, 'This model instance has unset input arguments. All input arguments must be set before saving.')
    )

  it 'should fail when attempting to set an non-existent property', ->

    life = new Weaver.Model()

    life.define("{
      itsShort
      itShouldBe(sweet)
    }")

    theLifeOfMan = life.instance()

    try
      theLifeOfMan.set('$theSecretOf', 'Easy to find')
    catch err

      assert.equal(err.message, '$theSecretOf is not a valid input argument for this model')

  it "should not allow assignment of value properties which contain the character '@'", ->

    life = new Weaver.Model()

    life.define("{
      itsShort
      <spendItAt>($place)
    }")

    theLifeOfMan = life.instance()

    try
      theLifeOfMan.set('$place', 'home')
    catch err
      assert.equal(err.message, 'Value property/Attribute strings cannot contain the cahracter \'@\'')


  it "should not allow assignment of input arguments which contain the character '$'", ->

    president = new Weaver.Model()

    president.define("{
      <has>($bestAsset)
    }")

    trump = president.instance()

    try
      trump.set('$bestAsset', '$$$')
    catch err
      assert.equal(err.message, 'Input argument strings cannot contain the character \'$\'')
