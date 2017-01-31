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

    thing = new Weaver.Model()
    thing.define("{
      <hasName>(John Doe)
    }")
    something = thing.instance()

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
      hasChild(Parent) {
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

      assert.equal(err.message, '$theSecretOf is not a valid input argument for this model.')



  it "should fail to 'set' a relation ", ->

    life = new Weaver.Model()

    life.define("{
      itsShort($isShort)
      itShouldBe(sweet)
    }")

    theLifeOfTurtle = life.instance()
    try
      theLifeOfTurtle.set('$isShort', 'Not at all. Your falsiest value, please.')
    catch err
      assert.equal(err.message, 'Cannot use \'set\' to add relation. Use \'add\' instead.')


  it "should fail to 'add' an attribute", ->

    country = new Weaver.Model()

    country.define("{
      hasName {
        <hasPrefix>($namePrefix)
        <hasActualName>($commonName)
      }
    }")

    america = country.instance()
    america.set('$commonName', 'America')
    america.set('$namePrefix', 'United States of')

    try
      america.add('$namePrefix', 'Trump towers present, the')
    catch err
      assert.equal(err.message, 'Cannot use \'add\' to set attribute. Use \'set\' instead.')



  it "should not allow assignment of value properties which contain the character '@'.", ->

    life = new Weaver.Model()

    life.define("{
      itsShort
      <spendItAt>($place)
    }")

    theLifeOfMan = life.instance()

    try
      theLifeOfMan.set('$place', 'home')
    catch err
      assert.equal(err.message, "Value property/Attribute strings cannot contain the character '@'.")




  it "should not allow assignment of input arguments which contain the character '$'.", ->

    president = new Weaver.Model()

    president.define("{
      <has>($bestAsset)
    }")

    trump = president.instance()
    try
      trump.set('$bestAsset', '$$$')
    catch err
      assert.equal(err.message, "Input argument strings cannot contain the character '$'.")


