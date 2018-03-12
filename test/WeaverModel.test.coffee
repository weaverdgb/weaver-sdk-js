weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')
cuid   = require('cuid')

describe 'WeaverModel test', ->

  it 'should load in a model from the server', ->
    Weaver.Model.load("test-model", "1.1.2").then((Model) ->
      assert.equal(Model.definition.name,    "test-model")
      assert.equal(Model.definition.version, "1.1.2")
    )

  it 'should reload a model from the server', ->
    Weaver.Model.reload("test-model", "1.1.2").then((Model) ->
      assert.equal(Model.definition.name,    "test-model")
      assert.equal(Model.definition.version, "1.1.2")
    )

  it 'should load in a model from the server with another version', ->
    Weaver.Model.load("test-model", "1.2.0").then((Model) ->
      assert.equal(Model.definition.name,    "test-model")
      assert.equal(Model.definition.version, "1.2.0")
    )

  it 'should reload a model from the server with another version', ->
    Weaver.Model.reload("test-model", "1.2.0").then((Model) ->
      assert.equal(Model.definition.name,    "test-model")
      assert.equal(Model.definition.version, "1.2.0")
    )

  it 'should list models from the server', ->
    Weaver.Model.list().then((models)->
      assert.isDefined(models['test-model'])
      assert.isDefined(models['test-model'].length)
    )

  it 'should fail on a not existing model', ->
    Weaver.Model.load("ghost-model", "1.1.2").then((Model) ->
      assert(false)
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.MODEL_NOT_FOUND)
    )

  it 'should fail on an include cycle', ->
    Weaver.Model.load("test-cycle-model", "0.0.1").then((Model) ->
      assert(false)
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.MODEL_INCLUSION_CYCLE)
    )

  it 'should fail on a not existing version of an existing model', ->
    Weaver.Model.load("test-model", "1.99.1").then((Model) ->
      assert(false)
    ).catch((error)->
      assert.equal(error.code, Weaver.Error.MODEL_VERSION_NOT_FOUND)
    )

  describe 'with a loaded model', ->
    model = {}

    before ->
      Weaver.Model.load("test-model", "1.2.0").then((m) ->
        model = m
      )

    it 'should set the type definition to the model class', ->
      Person = model.Person
      person = new Person()
      assert.equal(person.nodeRelation(person.model.getMemberKey()).first().id(), "#{model.definition.name}:#{person.className}")
      assert.equal(person.getMember()[0].id(), "#{model.definition.name}:#{person.className}")

    it 'should be able to configure the member relation', ->
      originalmember = model.definition.member
      model.definition.member = "member:rel"
      Person = model.Person
      person = new Person()
      assert.equal(person.nodeRelation("member:rel").first().id(), "#{model.definition.name}:#{person.className}")
      model.definition.member = originalmember

    it 'should fallback to the default _member relation', ->
      originalmember = model.definition.member
      delete model.definition.member
      Person = model.Person
      person = new Person()
      assert.equal(person.nodeRelation("_member").first().id(), "#{model.definition.name}:#{person.className}")
      model.definition.member = originalmember

    it 'should set attributes on model instances', ->
      Person = model.Person
      person = new Person()
      person.set('fullName', "John Doe")
      assert.isDefined(person.attributes().fullName)
      assert.isUndefined(person.attributes().hasFullName)

    it 'should get attributes on model instances', ->
      Person = model.Person
      person = new Person()
      person.set('fullName', "John Doe")
      assert.equal(person.get('fullName'), "John Doe")
      assert.isDefined(person.attributes().fullName)
      assert.isUndefined(person.attributes().hasFullName)

    it 'should set attributes on model instances by inheritance', ->
      c = new model.Country()
      c.set('areaName', "Area 51")
      c.set('squareMeter', 200)
      assert.equal(c.get('areaName'), "Area 51")
      assert.equal(c.get('squareMeter'), 200)

    it 'should set relations on model instances by inheritance', ->
      c1 = new model.Country()
      c2 = new model.Country()
      c1.relation("intersection").add(c2)

      assert.equal(c1.relation("intersection").first().id(), c2.id())

    it 'should read range on model class', ->
      Person = model.Person
      person = new Person()
      person.getRanges('livesIn').should.eql(['House'])
      person.getRanges('isIn').should.eql(['House', 'Office'])

    it 'should add allowed relations by correct range', ->
      Person   = model.Person
      House = model.House
      person = new Person()
      person.relation("hasFriend").add(new Person())
      person.relation("livesIn").add(new House())

    it 'should deny allowed relations by different range', ->
      Person   = model.Person
      Building = model.Building
      person = new Person()
      assert.throws((-> person.relation("livesIn").add(new Weaver.Node())))
      assert.throws((-> person.relation("livesIn").add(new Person())))

    it 'should deny setting invalid model attributes', ->
      Person = model.Person
      person = new Person()
      assert.throws((-> person.set('hasFullName', "John Doe")))

    it 'should deny getting direct instance attributes', ->
      Person = model.Person
      person = new Person()
      person.set('fullName', "John Doe")
      assert.throws((-> person.get('hasFullName')))

    it 'should bootstrap a model', ->
      model.bootstrap().then(->
        new Weaver.Query().restrict('test-model:Person').find()
      ).should.eventually.have.length.be(1)

    it 'should fail saving with type definition that is not yet bootstrapped', ->
      Person = model.Person
      person = new Person()
      person.set("fullName", "Valan son of Glassan")
      assert.throws(person.save)

    describe 'that is bootstrapped', ->
      before ->
        model.bootstrap()

      it 'should not do anything on multiple bootstraps', ->
        model.bootstrap().then(->
          new Weaver.Query().restrict('test-model:Person').find()
        ).should.eventually.have.length.be(1)

      it 'should have init member after a bootstrap', ->
        expect(model).to.have.property('City').to.have.property('Rotterdam').be.defined

      it 'should have init member on load a rebootstrap', ->
        Weaver.Model.load(model.definition.name, model.definition.version).then((reloaded) ->
          reloaded.bootstrap().then(->
            expect(reloaded).to.have.property('City').to.have.property('Rotterdam').be.defined
          )
        )

      it 'should succeed saving with type definition that is bootstrapped', ->
        Person = model.Person
        person = new Person()
        person.set("fullName", "Arild Askholmen")
        person.save()

      it 'should succeed saving with type definition of an included model', ->
        Document = model.td.Document
        document = new Document()
        document.save()
        .then(->
          Document.load(document.id())
        ).then((loaded)->
          expect(loaded.id()).to.equal(document.id())
        )

      it 'should succeed saving with exteinded type definition of an included model', ->
        Document = model.DeliveryNotice
        document = new Document()
        document.set('at', 'work')
        document.save()
        .then(->
          Document.load(document.id())
        ).then((loaded)->
          expect(loaded.id()).to.equal(document.id())
        )

      it 'should succeed save one instance with single type', ->
        Weaver.Node.loadFromGraph('test-model:Leiden', model.getGraph()).then((node)->
          node.relation('rdf:type').all().should.have.length.be(1)
        )

      it 'should succeed save inherit relation', ->
        Weaver.Node.loadFromGraph('test-model:AreaSection', model.getGraph()).then((node)->
          assert.isDefined(node.relation('rdfs:subClassOf').first())
        )

      it 'should succeed saving all instances', ->
        new Weaver.Query().restrictGraphs(model.getGraph()).hasRelationOut('rdf:type', Weaver.Node.getFromGraph('test-model:City', model.getGraph()))
        .find().then((nodes) -> i.id() for i in nodes)
        .should.eventually.be.eql(["test-model:Delft", "test-model:Rotterdam", "test-model:Leiden", "test-model:CityState"])

      it 'should have the init instances as members of the model class', ->
        expect(model).to.have.property('City').to.have.property('Rotterdam')

      it 'should not have the init instances as members of the model', ->
        expect(model).to.not.have.property('Rotterdam')

      it 'should have the init instances as members of the model class and model if they are also a class', ->
        expect(model).to.have.property('City').to.have.property('CityState')
        expect(model).to.have.property('CityState')
        constructor = model.CityState
        classMember = model.City.CityState
        expect("#{model.definition.name}:#{constructor.className}").to.equal(classMember.id())

      it 'should throw an error when saving without setting required attributes', ->
        Person = model.Person
        person = new Person()
        assert.throws(person.save)

      it 'should throw an error when saving without setting required attributes', ->
        Person = model.Person
        person = new Person()
        assert.throws(person.save)

      it 'should throw an error when saving with min relations required', ->
        b = new model.Building()
        assert.throws(b.save)
        p = new model.Person()
        p.set("fullName", "Hola")
        b.relation("buildBy").add(p)
        b.save()

      it 'should throw an error when saving with max relations required', ->
        b = new model.Building()
        p1 = new model.Person()
        p1.set("fullName", "Hola 1")
        p2 = new model.Person()
        p2.set("fullName", "Hola 2")
        p3 = new model.Person()
        p3.set("fullName", "Hola 3")

        b.relation("buildBy").add(p1)
        b.relation("buildBy").add(p2)
        b.relation("buildBy").add(p3)
        assert.throws(b.save)

      it 'should allow saving at max relations required', ->
        b = new model.Building()
        p1 = new model.Person()
        p1.set("fullName", "Hola 1")
        p2 = new model.Person()
        p2.set("fullName", "Hola 2")

        b.relation("buildBy").add(p1)
        b.relation("buildBy").add(p2)
        b.save()

      it 'should list attributes', ->
        p1 = new model.Person()
        p1.set("fullName", "Hola 1")

        assert.equal(p1.attributes()['fullName'], 'Hola 1')

      it 'should list relations', ->
        b = new model.Building()
        p = new model.Person("personId")
        p.set("fullName", "Hola 1")
        b.relation("buildBy").add(p)

        assert.equal(b.relations()['buildBy'].first().id(), 'personId')

      it 'should load model instances', ->
        p = new model.Person()
        p.set('fullName', 'A testy user')
        p.save().then(->
          model.Person.load(p.id())
        ).then((person) ->
          person.should.be.instanceOf(model.Person)
          expect(person.get('fullName')).to.equal('A testy user')
        )

      it 'should load model instances that are not of the last item', ->
        c = new model.Country()
        c.set('areaName', 'testland')
        c.set('squareMeter', 12)
        c.save().then(->
          model.Country.load(c.id())
        ).then((country) ->
          country.should.be.instanceOf(model.Country)
        )

      it 'should add an existing node to a model', ->
        person = new Weaver.Node()
        model.Person.addMember(person)
        person.save().then(->
          model.Person.load(person.id())
        ).then((person)->
          person.should.be.instanceOf(model.Person) 
        )

      it 'should add an existing node to an other model', ->
        tree = new Weaver.Node()
        tree.relation('hasLeaf').add(new Weaver.Node())
        model.Country.addMember(tree)

        tree.save().then(->
          model.Country.load(tree.id())
        ).then((country)->
          country.should.be.instanceOf(model.Country) 
        )

      it 'should add an existing node to two other models', ->
        tree = new Weaver.Node()
        tree.relation('hasLeaf').add(new Weaver.Node())
        model.Country.addMember(tree)
        model.Person.addMember(tree)
        tree.save().then(->
          model.Country.load(tree.id())
        ).then((country)->
          country.should.be.instanceOf(model.Country) 
        ).then(->
          model.Person.load(tree.id())
        ).then((person)->
          person.should.be.instanceOf(model.Person)
        )
