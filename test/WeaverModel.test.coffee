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
    Weaver.Model.load('ghost-model', '1.1.2').should.be.rejectedWith(Weaver.Error.MODEL_NOT_FOUND)

  it 'should be possible to have an include cycle', ->
    Weaver.Model.load('test-cycle-model', '0.0.1').then((model)->
      r = new model.cycle.cycle.cycle.cycle.Robot()
    )

  it 'should fail on a not existing version of an existing model', ->
    Weaver.Model.load('test-model', '1.99.1').should.be.rejectedWith(Weaver.Error.MODEL_VERSION_NOT_FOUND)

  describe 'with a loaded model', ->
    model = {}

    before ->
      Weaver.Model.load("test-model", "1.2.0").then((m) ->
        model = m
        model.bootstrap()
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

    it 'should unset attributes on model instances', ->
      Person = model.Person
      person = new Person()
      person.set('fullName', "John Doe")
      person.unset('fullName')

    it 'should set attributes the node way on model instances', ->
      Person = model.Person
      person = new Person()
      person.nodeSet('hasFullName', 'John Doe')
      assert.isDefined(person.attributes().fullName)
      assert.isUndefined(person.attributes().hasFullName)
      expect(person.nodeGet('hasFullName')).to.equal('John Doe')

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

    it 'should set relation on included model instances', ->
      s = new model.Shelf()
      d = new model.td.Document()
      s.relation('supports').add(d)

    it 'should set attributes on included model instances by inheritance', ->
      p = new model.Passport()
      b = new model.Person()
      a = new model.td.Autograph()

      p.set('fileName', 'passport.pdf')

      p.relation('ownedBy').add(b)
      p.relation('signedWith').add(a)
      a.relation('carbonCopy').add(p)

    it 'should set relations on model instances by inheritance', ->
      c1 = new model.Country()
      c2 = new model.Country()
      c1.relation("intersection").add(c2)

      assert.equal(c1.relation("intersection").first().id(), c2.id())

    it 'should read range on model class', ->
      Person = model.Person
      person = new Person()
      person.getRanges('livesIn').should.eql(['test-model:House'])
      person.getRanges('isIn').should.eql(['test-model:House', 'test-model:Office'])

    it 'should add allowed relations by correct range', ->
      Person = model.Person
      House = model.House
      person = new Person()
      person.relation("hasFriend").add(new Person())
      person.relation("livesIn").add(new House())

    it 'should add allowed relations by correct sub range', ->
      p = new model.td.test.td.test.Person()
      c = new model.td.Clerk()
      p.relation("hasFriend").add(c)
      c.relation("hasFriend").add(p)

    it 'should deny allowed relations by different range', ->
      Person   = model.Person
      Building = model.Building
      person = new Person()
      assert.throws((-> person.relation("livesIn").add(new Person())))

    it 'should deny setting invalid model attributes', ->
      Person = model.Person
      person = new Person()
      assert.throws((-> person.set('hasFullName', "John Doe")))

    it 'should deny getting direct instance attributes', ->
      Person = model.Person
      person = new Person()
      person.set('fullName', "John Doe")
      expect(person.get('hasFullName')).to.be.undefined

    it 'should not deny getting invalid attributes but instead return undefined', ->
      person = new model.Person()
      expect(person.get("totallyNotAnAttributeOfTheModel")).to.be.undefined

    it 'should bootstrap a model', ->
      model.bootstrap().then(->
        new Weaver.Query().restrict('test-model:Person').find()
      ).should.eventually.have.length.be(1)

    it 'should bootstrap an already bootstrapped model with one extra node', ->
      model.bootstrap()
      .then(->
        Weaver.Node.getFromGraph('test-model:House', model.getGraph()).destroy()
      ).then(->
        model.bootstrap()
      )

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

      it 'should load the to model nodes by using load function on half loaded node', ->
        loadedNode = null
        p = new model.Person()
        o = new model.Office()
        c = new model.Country()
        p.relation('worksIn').add(o)
        o.relation('placedIn').add(c)
        p.save()
        .then(->
          model.Person.load(p.id())
        ).then((node)->
          expect(node).to.be.instanceOf(model.Person)
          node.relation('worksIn').first().load()
        ).then((node)->
          expect(node).to.be.instanceOf(model.Office)
          node.relation('placedIn').first().load()
        ).then((node)->
          expect(node).to.be.instanceOf(model.Country)
        )

      it 'should load the to model nodes if the node is in another graph', ->
        loadedNode = null
        p = new model.Person()
        o = new model.Office(undefined, 'some-graph')
        c = new model.Country()
        p.relation('worksIn').add(o)
        o.relation('placedIn').add(c)
        p.save()
        .then(->
          model.Person.load(p.id())
        ).then((node)->
          expect(node).to.be.instanceOf(model.Person)
          node.relation('worksIn').first().load()
        ).then((node)->
          expect(node).to.be.instanceOf(model.Office)
          expect(node.getGraph()).to.equal('some-graph')
          expect(node.relation('placedIn').first().id()).to.equal(c.id())
        )

      it 'should succeed saving with type definition that is bootstrapped', ->
        Person = model.Person
        person = new Person()
        person.set("fullName", "Arild Askholmen")
        person.save()

      it 'should succeed saving with type definition of an included model', ->
        Person = model.Person
        person = new Person()
        person.set("fullName", "Arild Askholmen")

        Document = model.td.Document
        document = new Document()

        person.relation('signed').add(document)
        person.save()
        .then(->
          Document.load(document.id())
        ).then((loaded)->
          expect(loaded.id()).to.equal(document.id())
        )

      it 'should succeed setting attribuges at an extended type definition of an included model', ->
        Document = model.DeliveryNotice
        document = new Document()
        document.set('at', '2017-01-02')
        expect(document.getDataType('at')).to.equal('xsd:dateTime')
        document.set('fileName', 'print.pdf')
        expect(document.getDataType('hasFileName')).to.equal('string')
        document.save()
        .then(->
          Document.load(document.id())
        ).then((loaded)->
          expect(loaded.id()).to.equal(document.id())
          expect(loaded.get('at')).to.equal(1483315200000)
          expect(loaded.get('fileName')).to.equal('print.pdf')
          expect(loaded.getDataType('at')).to.equal('xsd:dateTime')
          expect(loaded.getDataType('hasFileName')).to.equal('string')
        )

      it 'should succeed save one instance with single type', ->
        Weaver.Node.loadFromGraph('test-model:Leiden', model.getGraph()).then((node)->
          node.relation('rdf:type').all().should.have.length.be(1)
        )

      it 'should have bootstrapped some instance with two types', ->
        Weaver.Node.loadFromGraph('test-model:EmpireState', model.getGraph()).then((node)->
          node.relation('rdf:type').all().should.have.length.be(2)
        )

      it 'should succeed save inherit relation', ->
        Weaver.Node.loadFromGraph('test-model:AreaSection', model.getGraph()).then((node)->
          assert.isDefined(node.relation('rdfs:subClassOf').first())
        )

      it 'should succeed saving all instances', ->
        new Weaver.Query().restrictGraphs(model.getGraph()).hasRelationOut('rdf:type', Weaver.Node.getFromGraph('test-model:City', model.getGraph()))
        .find().then((nodes) -> i.id() for i in nodes)
        .should.eventually.have.members(["test-model:Delft", "test-model:Rotterdam", "test-model:Leiden", "test-model:CityState", "test-model:EmpireState"])

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

      describe 'and some data', ->
        one = {}

        before ->
          one = new model.Person()
          one.set('fullName', 'One')
          two = new model.Person()
          two.set('fullName', 'Two')
          one.relation('hasFriend').add(two)
          one.save()

        it 'should instantiate the correct class for relations on load', ->
          model.Person.load(one).then((person) ->
            expect(person.relation('hasFriend').first()).to.be.an.instanceof(model.Person)
          )

        it 'should allow to get an attribute after load', ->
          model.Person.load(one.id()).then((person) ->
            person.relation('hasFriend').first().load()
          ).then((loadedTwo) ->
            expect(loadedTwo.get('fullName')).to.equal('Two')
          )

        it 'should allow you to set attributes on relations', ->
          model.Person.load(one.id()).then((personOne) ->
            rel = personOne.relation('hasFriend')
            rel.to(rel.all()[0])
          ).then((relNode) ->
            relNode.set('friendScore', '-1')
            relNode.save()
          ).then(->
            model.Person.load(one.id())
          ).then((personOne) ->
            rel = personOne.relation('hasFriend')
            rel.to(rel.all()[0])
          )

  describe 'with the animal model', ->
    model = {}

    before ->
      Weaver.Model.load("animal-model", "1.0.0").then((m) ->
        model = m
        model.bootstrap()
      )

    it 'set briefly defined attributes', ->
      page = new model.WikiPage()
      page.set('summary', '🦒')
      assert.equal(page.get('summary'), '🦒')
      page.save().then(->
        model.WikiPage.load(page.id())
      ).then((node)->
        assert.equal(node.get('summary'), '🦒')
      )

    it 'use the datatype specified in the model', ->
      page = new model.WikiPage()
      page.set('location', 'https://en.wikipedia.org/wiki/Giraffe')
      assert.equal(page.getDataType('location'), 'xsd:anyURI')
