require("./test-suite")

describe 'WeaverModel', ->


  ###

      CREATION STUFF

  ###


  it 'should create a new node', ->

    Something = new Weaver.Model()
    Something.define("{}")
    helloWorld = Something.instance()

    helloWorld.save().then( (res)->
      assert.isDefined(res.instance)
    )



  it 'should create a new node, with a specified id', ->

    Something = new Weaver.Model()
    Something.define("(chaise_lounge){}")
    helloWorld = Something.instance()

    helloWorld.save().then( (res)->
      assert.equal(res.id(), 'chaise_lounge')
    )



  it 'should create a new node with a static attribute', ->

    Thing = new Weaver.Model()
    Thing.define("{
      <hasName>(John Doe)
    }")

    something = Thing.instance()
    something.save().then( (res)->
      assert.equal(res.attributes.hasName, 'John Doe')
    )



  it 'should create a new node with a dynamic attribute', ->

    Something = new Weaver.Model()
    Something.define("{
      <hasName>($name)
    }")

    hal = Something.instance()
    hal.set('name', 'H.A.L.')

    hal.save().then( (res)->
      assert.equal(res.get('name'), 'H.A.L.')
    )



  it 'should create a new node with a relation', ->

    Something = new Weaver.Model()
    Something.define("{
      wasBuiltOn
    }")

    hal = Something.instance()

    hal.save().then( (res)->
      assert.isDefined(res.relation('wasBuiltOn'))
    )



  it 'should create a new node with a static relation', ->

    new Weaver.Node('unknown').save().then(->

      MysteriousRelic = new Weaver.Model()
      MysteriousRelic.define("{
        wasFoundAt(unknown)
      }")

      magicRing = MysteriousRelic.instance()

      magicRing.save().then( (res)->
        assert.isDefined(res.relation('wasFoundAt').nodes['unknown'])
      )
    )



  it 'should create a new node with a dynamic relation', ->

    new Weaver.Node('Valhalla').save().then(->

      RespectableViking = new Weaver.Model()
      RespectableViking.define("{
        spendsAfterlifeIn($heaven)
      }")

      thomund = RespectableViking.instance()
      thomund.add('heaven', 'Valhalla')

      thomund.save().then( (res)->
        assert.equal(res.get('heaven')[0].id(),'Valhalla')
      )
    )



  it 'should allow for nested relationships', ->

    Family = new Weaver.Model()
    Family.define("{
      <hasName>($grandParent)
      hasChild {
        <hasName>($parent)
        hasChild{
          <hasName>($child)
        }
      }
    }")

    theAddams = Family.instance()

    theAddams.set('grandParent', 'Grandpa Slurk')
    theAddams.set('parent', 'Father Murk')
    theAddams.set('child', 'Little Durk')

    theAddams.save().then( (res)->
      grandpa = res
      parent = prop for key,prop of grandpa.relation('hasChild').nodes
      child = prop for key,prop of parent.relation('hasChild').nodes

      assert.equal(grandpa.get('hasName'), 'Grandpa Slurk')
      assert.equal(parent.get('hasName'), 'Father Murk')
      assert.equal(child.get('hasName') 'Little Durk')
    )



  it 'shouldn\'t instantiate a model instance when there are unset input fields', ->

    Smurf = new Weaver.Model()
    Smurf.define("{
      <hasName>($name)
    }")

    grumpy = Smurf.instance()

    grumpy.save().catch( (err)->
      assert.equal(err.message, 'This model instance has unset input arguments. All input arguments must be set before saving.')
    )



  it 'should fail when attempting to set an non-existent property', ->

    Life = new Weaver.Model()

    Life.define("{
      itsShort
      itShouldBe(sweet)
    }")

    theLifeOfMan = Life.instance()
    try
      theLifeOfMan.set('theSecretOf', 'Easy to find')
    catch err

      assert.equal(err.message, 'theSecretOf is not a valid input argument for this model.')



  it "should fail to 'set' a relation ", ->

    Life = new Weaver.Model()

    Life.define("{
      itsShort($isShort)
      itShouldBe(sweet)
    }")

    theLifeOfTurtle = Life.instance()
    try
      theLifeOfTurtle.set('isShort', 'Not at all. Your falsiest value, please.')
    catch err
      assert.equal(err.message, 'Cannot use \'set\' to add relation. Use \'add\' instead.')



  it "should fail to 'add' an attribute", ->

    Country = new Weaver.Model()

    Country.define("{
      hasName {
        <hasPrefix>($namePrefix)
        <hasActualName>($commonName)
      }
    }")

    america = Country.instance()
    america.set('commonName', 'America')
    america.set('namePrefix', 'United States of')

    try
      america.add('namePrefix', 'Trump towers present, the')
    catch err
      assert.equal(err.message, 'Cannot use \'add\' to set attribute. Use \'set\' instead.')



  it "should not allow assignment of value properties which contain the character '@'.", ->

    Life = new Weaver.Model()

    Life.define("{
      itsShort
      <spendItAt>($place)
    }")

    theLifeOfMan = Life.instance()

    try
      theLifeOfMan.set('place', 'c@ve')
    catch err
      assert.equal(err.message, "Value property/Attribute strings cannot contain the character '@'.")



  it "should not allow assignment of input arguments which contain the character '$'.", ->

    President = new Weaver.Model()

    President.define("{
      <has>($bestAsset)
    }")

    trump = President.instance()
    try
      trump.set('bestAsset', '$$$')
    catch err
      assert.equal(err.message, "Input argument strings cannot contain the character '$'.")


  ###

      READING STUFF

  ###

  Fruit = new Weaver.Model()
  Fruit.define("{
      type($type)
      growsOn {
        type($bearer)
        growsIn(TheGround)
      }
      <hasName>($name)
      hasTaste($taste)
      hasColour($colour)
      hasSeeds
    }")

  greenApple = Fruit.instance()
  greenApple.set('type', 'Apple')
  .set('bearer', 'Tree')
  .set('name', 'greeny')
  .set('taste', 'Sour')
  .set('colour', 'Green')

  redApple = Fruit.instance()
  redApple.set('type', 'Apple')
  .set('bearer', 'Tree')
  .set('name', 'sir red')
  .set('taste', 'Sweet')
  .set('colour', 'Red')

  lemon = Fruit.instance()
  lemon.set('type', 'Lemon')
  .set('bearer', 'Tree')
  .set('name', 'zest')
  .set('taste', 'Sour')
  .set('colour', 'Yellow')

  strawberry = Fruit.instance()
  strawberry.set('type', 'Strawberry')
  .set('bearer', 'Bush')
  .set('name', 'greeny')
  .set('taste', 'Sour')
  .set('colour', 'Red')

  demonicStrawberry = Fruit.instance()
  demonicStrawberry.set('type', 'Apple')
  .set('bearer', 'Bush')
  .set('name', 'greeny')
  .set('taste', 'Sour')
  .set('colour', 'Black')

  it ' is just here to instantiate stuff for the reading tests', (done)->

    types = []
    instances = []

    # Add the types, (as in schema types)
    types.push(
      new Weaver.Node('Yellow').save(),
      new Weaver.Node('Red').save(),
      new Weaver.Node('Black').save(),
      new Weaver.Node('Green').save(),

      new Weaver.Node('Sweet').save(),
      new Weaver.Node('Sour').save(),

      new Weaver.Node('Strawberry').save(),
      new Weaver.Node('Apple').save(),
      new Weaver.Node('Lemon').save(),

      new Weaver.Node('Tree').save(),
      new Weaver.Node('Bush').save(),
      new Weaver.Node('TheGround').save(),
      new Weaver.Node('Burning').save(),
    )

    # When the types (ie Schema), have all been created, it will be safe to create the instance data
    instances.push(
      redApple.save(),
      lemon.save(),
      strawberry.save(),
      demonicStrawberry.save(),
      greenApple.save()
    )

    types.all().then(->
      instances.all().then(->
        done()
      )
    )

  it 'should find all the fruit', ->

    Fruit.query().then( (res)->
      assert.equal(res.length, 5)
      assert.equal(root.instance['growsOn'][0]['growsIn'][0]._id, 'TheGround')
    )

  it 'should be able to query based on subsets of models', ->

    Apple = Fruit.modelSubSet()
    Apple.define('type', 'Apple')
    Apple.define('bearer', 'AppleTree')
    # The 'Apple' subset looks like a Fruit model, but two of it's variable fields have been made static.
    # This saves on 'set' statements during creation, and gives more accurate results on query

    Apple.query().then( (res)->
      assert.equal(res.length, 2)
      assert.equal(apple.get('type'), 'Apple') for apple in res
    )



  ###

      ADVANCED

  ###

  it 'should be capable of building models from other models', ->

    Letter = new Weaver.Model()
    Letter.define("{
      <hasSound>($sound)
    }")

    Word = new Weaver.Model()
    Word.define("{
      consistsOf(@Letter)
      <hasMeaning>($meaning)
      ~isComposedOf(@Word)
    }").save()

    Language = new Weaver.Model()
    Language.define("{
      <hasName>($name)
      isSpokenIn($country)
      hasDictionary {
        hasWord(@Word)
      }
    }").save()

    a = Letter.instance()
    a.set('sound', 'aaah')
    a.save()

    aaa = Word.modelSubSet()
    aaa.define(consistsOf, Letter.id()) #Letter can be a WeaverModel entity retrieved from the database
    aaa.set('meaning', 'A sound a person makes when they wish to express satisfaction. Used to express fear, in rare or theatrical cases.')
    aaa.save()

    english = Language.instance()
    english.define('hasWord', aaa.id())

    english.save()




