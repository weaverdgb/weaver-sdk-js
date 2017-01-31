require("./test-suite")

describe 'WeaverModel test', ->


  it 'should create a new node', ->

    something = new Weaver.Model()

    something.define("{}")

    helloWorld = something.instance()

    helloWorld.save().then( (res)->
      assert.isDefined(res[0].nodeId)
    )

  it 'should create a new node with an attribute', ->

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

  it 'should create a new node with a specified relation', ->

    something = new Weaver.Model()

    something.define("{
      <hasName>($name)
      hasFriend($friend)
    }")

    hal = something.instance()

    dave = new Weaver.Node('Dave')
    dave.save().then(->

      hal.set('$name', 'H.A.L.')
      hal.add('$friend', 'Dave')

      hal.save().then( (res)->
        assert.isDefined(res[0].relation('hasFriend').nodes['Dave'])
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

  it "should not allow assignment of value properties which contian the character '@'", ->

    life = new Weaver.Model()

    life.define("{
      itsShort
      spendItAt($place)
    }")

    theLifeOfMan = life.instance()

    try
      theLifeOfMan.set('$place', 'home')
    catch err
      assert.equal(err.message, 'Value property/Attribute strings cannot contain the cahracter \'@\'')



