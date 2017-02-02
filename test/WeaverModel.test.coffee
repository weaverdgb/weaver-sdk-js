require("./test-suite")

describe 'WeaverModel', ->


#  it 'should create a new node', ->
#
#    Something = new Weaver.Model()
#    Something.define("{}")
#    helloWorld = Something.modelInstance()
#
#    helloWorld.save().then( (res)->
#      assert.isDefined(res.nodeId)
#    )
#
#
#
#  it 'should create a new node, with a specified id', ->
#
#    Something = new Weaver.Model()
#    Something.define("(chaise_lounge){}")
#    helloWorld = Something.modelInstance()
#
#    helloWorld.save().then( (res)->
#      assert.equal(res.nodeId, 'chaise_lounge')
#    )



  it 'should create a new node with a static attribute', ->

    Thing = new Weaver.Model()
    Thing.define("{
      <hasName>(John Doe)
      type {
        <name>
      }
    }")

    something = Thing.modelInstance()

    something.save().then( (res)->
      assert.equal(res.attributes.hasName, 'John Doe')
    )
#
#
#
#  it 'should create a new node with a dynamic attribute', ->
#
#    Something = new Weaver.Model()
#    Something.define("{
#      <hasName>($name)
#    }")
#
#    hal = Something.modelInstance()
#    hal.set('$name', 'H.A.L.')
#
#    hal.save().then( (res)->
#      assert.equal(res.attributes.hasName, 'H.A.L.')
#    )
#
#
#
#  it 'should create a new node with a relation', ->
#
#    Something = new Weaver.Model()
#    Something.define("{
#      wasBuiltOn
#    }")
#
#    hal = Something.modelInstance()
#
#    hal.save().then( (res)->
#      assert.isDefined(res.relation('wasBuiltOn'))
#    )
#
#
#
#  it 'should create a new node with a static relation', ->
#
#    new Weaver.Node('unknown').save().then(->
#
#      MysteriousRelic = new Weaver.Model()
#      MysteriousRelic.define("{
#        wasFoundAt(unknown)
#      }")
#
#      magicRing = MysteriousRelic.modelInstance()
#
#      magicRing.save().then( (res)->
#        assert.isDefined(res.relation('wasFoundAt').nodes['unknown'])
#      )
#    )
#
#
#
#  it 'should create a new node with a dynamic relation', ->
#
#    new Weaver.Node('Valhalla').save().then(->
#
#      RespectableViking = new Weaver.Model()
#      RespectableViking.define("{
#        spendsAfterlifeIn($heaven)
#      }")
#
#      thomund = RespectableViking.modelInstance()
#      thomund.add('$heaven', 'Valhalla')
#
#      thomund.save().then( (res)->
#        assert.isDefined(res.relation('spendsAfterlifeIn').nodes['Valhalla'])
#      )
#    )
#
#
#
#  it 'should allow for nested relationships', ->
#
#    Family = new Weaver.Model()
#    Family.define("{
#      <hasName>($grandParent)
#      hasChild(Parent) {
#        <hasName>($parent)
#        hasChild{
#          <hasName>($child)
#        }
#      }
#    }")
#
#    theAddams = Family.modelInstance()
#
#    console.log(theAddams)
#
#    theAddams.set('$grandParent', 'Grandpa Slurk')
#    theAddams.set('$parent', 'Father Murk')
#    theAddams.set('$child', 'Little Durk')
#
#    theAddams.save().then( (res)->
#      grandpa = res
#      parent = prop for key,prop of grandpa.relation('hasChild').nodes
#      child = prop for key,prop of parent.relation('hasChild').nodes
#
#      assert.equal(grandpa.attributes.hasName, 'Grandpa Slurk')
#      assert.equal(parent.attributes.hasName, 'Father Murk')
#      assert.equal(child.attributes.hasName, 'Little Durk')
#    )
#
#
#
#  it 'shouldn\'t instantiate a model instance when there are unset input fields', ->
#
#    Smurf = new Weaver.Model()
#    Smurf.define("{
#      <hasName>($name)
#    }")
#
#    grumpy = Smurf.modelInstance()
#
#    grumpy.save().catch( (err)->
#      assert.equal(err.message, 'This model instance has unset input arguments. All input arguments must be set before saving.')
#    )
#
#
#
#  it 'should fail when attempting to set an non-existent property', ->
#
#    Life = new Weaver.Model()
#
#    Life.define("{
#      itsShort
#      itShouldBe(sweet)
#    }")
#
#    theLifeOfMan = Life.modelInstance()
#    try
#      theLifeOfMan.set('$theSecretOf', 'Easy to find')
#    catch err
#
#      assert.equal(err.message, '$theSecretOf is not a valid input argument for this model.')
#
#
#
#  it "should fail to 'set' a relation ", ->
#
#    Life = new Weaver.Model()
#
#    Life.define("{
#      itsShort($isShort)
#      itShouldBe(sweet)
#    }")
#
#    theLifeOfTurtle = Life.modelInstance()
#    try
#      theLifeOfTurtle.set('$isShort', 'Not at all. Your falsiest value, please.')
#    catch err
#      assert.equal(err.message, 'Cannot use \'set\' to add relation. Use \'add\' instead.')
#
#
#  it "should fail to 'add' an attribute", ->
#
#    Country = new Weaver.Model()
#
#    Country.define("{
#      hasName {
#        <hasPrefix>($namePrefix)
#        <hasActualName>($commonName)
#      }
#    }")
#
#    america = Country.modelInstance()
#    america.set('$commonName', 'America')
#    america.set('$namePrefix', 'United States of')
#
#    try
#      america.add('$namePrefix', 'Trump towers present, the')
#    catch err
#      assert.equal(err.message, 'Cannot use \'add\' to set attribute. Use \'set\' instead.')
#
#
#
#  it "should not allow assignment of value properties which contain the character '@'.", ->
#
#    Life = new Weaver.Model()
#
#    Life.define("{
#      itsShort
#      <spendItAt>($place)
#    }")
#
#    theLifeOfMan = Life.modelInstance()
#
#    try
#      theLifeOfMan.set('$place', 'home')
#    catch err
#      assert.equal(err.message, "Value property/Attribute strings cannot contain the character '@'.")
#
#
#
#
#  it "should not allow assignment of input arguments which contain the character '$'.", ->
#
#    President = new Weaver.Model()
#
#    President.define("{
#      <has>($bestAsset)
#    }")
#
#    trump = President.modelInstance()
#    try
#      trump.set('$bestAsset', '$$$')
#    catch err
#      assert.equal(err.message, "Input argument strings cannot contain the character '$'.")


