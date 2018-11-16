weaver  = require("./test-suite").weaver
wipeCurrentProject = require("./test-suite").wipeCurrentProject
Weaver  = require('../src/Weaver')
Promise = require('bluebird')

describe 'WeaverModelQuery test', ->
  model = {}

  before ->
    wipeCurrentProject().then(->
      Weaver.Model.load('test-model', '1.2.0')
    ).then((m) ->
      model = m
      model.bootstrap()
    ).then(->
      person = new model.Person('jondoeid', 'person-graph')
      person.set('fullName', 'John Doe')
      person.save()
    )

  it 'should do Weaver.Query on models', ->
    new Weaver.ModelQuery(model)
    .class(model.Person)
    .find()
    .then((instances) ->
      expect(instances).to.have.length.be(1)
      assert.equal(instances[0].constructor, model.Person)
      assert.equal(instances[0].get('fullName'), 'John Doe')
      assert.equal(instances[0].getGraph(), 'person-graph')
    )

  describe 'with a default model', ->
    before ->
      Weaver.useModel(model)

    it 'should do Weaver.Query from the default currentModel', ->
      assert.equal(model, Weaver.currentModel())

      new Weaver.ModelQuery()
      .class(model.Person)
      .count()
      .then((count) ->
        assert.equal(count, 1)
      )

    describe 'and test data', ->
      spain = {}
      hongkong = {}
      personB = undefined
      personBas = undefined
      clerk = undefined

      before ->
        head    = new model.Head("headA")
        spain   = new model.Country("Spain")
        nlds    = new model.Country("Netherlands")
        hongkong = new model.Country("HongKong")
        model.City.addMember(hongkong)
        personA = new model.Person("personA")
        personA.set('fullName', "Aby Delores")
        personA.relation('comesFrom').add(model.City.Rotterdam)
        personB = new model.Person("personB")
        personB.set('fullName', "Gaby Baby")
        personC = new model.Person("personC")
        personC.set('fullName', "#1")
        personA.relation("hasHead").add(head)
        personB.relation("hasHead").add(head)
        personB.relation("comesFrom").add(spain)
        personD = new model.Person("personD")
        personD.relation("comesFrom").add(model.City.Rotterdam)
        personD.relation("comesFrom").add(nlds)
        person人物 = new model.Person("person人物")
        person人物.relation("comesFrom").add(hongkong)
        person人物.relation("comesFrom").add(model.City.Rotterdam)
        person人物.relation("comesFrom").add(spain)
        basshouse = new model.House("basshouse")
        model.Office.addMember(basshouse)
        personBas = new model.Person("personBas")
        personBas.relation('livesIn').add(basshouse)
        personBas.relation('worksIn').add(basshouse)
        contract = new model.td.Document('basContract')
        delivery = new model.DeliveryNotice('basDeliveryOrder')
        personBas.relation('signed').add(contract)
        personBas.relation('signed').add(delivery)
        clerk = new model.td.Clerk('clerk')
        clerk.relation('comesFrom').add(model.City.Rotterdam)
        clerk.relation('authorised').add(contract)


        building = new model.House()
        area = new model.Area()
        building.relation("placedIn").add(area)
        building.relation("buildBy").add(personA)
        personB.relation("livesIn").add(building)
        personC.relation('comesFrom').add(model.City.CityState)
        Weaver.Node.batchSave([head, spain, nlds, personA, personB, personC, personD, person人物, basshouse, personBas, clerk])

      it 'should do an equalTo WeaverModelQuery', ->
        new Weaver.ModelQuery()
        .class(model.Person)
        .equalTo("Person.fullName", "Aby Delores")
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          p = instances[0]

          assert.equal(p.constructor, model.Person)
          assert.equal(p.id(), "personA")
          assert.equal(p.get('fullName'), 'Aby Delores')
          assert.equal(p.relation('hasHead').first().constructor, model.Head)
        )

      it 'should load model instances', ->
        new Weaver.ModelQuery()
          .restrict("personB")
          .first().should.eventually.be.instanceOf(model.Person)

      it 'should not error on livesInSomebuilding', ->
        new Weaver.ModelQuery()
        .equalTo("Person.fullName", "Gaby Baby")
        .find().then((persons)->
          persons.length.should.equal(1)
          persons[0].should.be.instanceOf(model.Person)
        )

      it 'handles selectOut correctly', ->
        new Weaver.ModelQuery()
        .restrict("personB")
        .selectOut("Person.livesIn", "Building.placedBy")
        .first().then((p)->
          expect(p).to.be.instanceOf(model.Person)
          b = p.relation('livesIn').first()
          expect(b).to.be.instanceOf(model.House)
          a = b.relation('placedIn').first()
          expect(a).to.be.instanceOf(model.Area)
        )

      it 'translates selectOut correctly (whitebox testing)', ->
        q = new Weaver.ModelQuery()
          .restrict("personB")
          .selectOut("Person.livesIn", "Building.placedBy")

        expect(q).to.have.property('_selectOut').to.have.length.be(1)
        expect(q._selectOut[0]).to.have.length.be(2)

      it 'should do selectRelation correctly', ->
        new Weaver.ModelQuery(model)
        .hasRelationOut("Person.comesFrom")
        .hasRelationOut("Person.hasHead")
        .selectRelations("Person.comesFrom")
        .first().then((r)->
          expect(r).to.be.instanceOf(model.Person)
          expect(r.relation('comesFrom').first()).to.be.defined
          expect(r.relation('hasHead').first()).to.not.be.defined
        )

      it 'should do a hasRelationIn WeaverModelQuery', ->
        new Weaver.ModelQuery()
        .hasRelationIn("Person.someRelation")
        .find()
        .then((instances) ->
          assert.equal(instances.length, 0)
        )

      it 'should fail on wrong key', ->
        q = new Weaver.ModelQuery()
        assert.throws((-> q.hasRelationIn("someRelation")))

      it 'should allow relations to a model instance', ->
        new Weaver.ModelQuery().hasRelationOut('Person.comesFrom', spain).find().should.eventually.have.length.be(2)

      it 'should allow relations to a model class instance', ->
        new Weaver.ModelQuery().hasRelationOut('Person.comesFrom', model.City.Rotterdam).find().should.eventually.have.length.be(4)

      it 'should allow relations to a model class instance that is also a class', ->
        new Weaver.ModelQuery().hasRelationOut('Person.comesFrom', model.City.CityState).find().should.eventually.have.length.be(1)

      it 'should allow relations to a model class', ->
        new Weaver.ModelQuery().hasRelationOut('Person.comesFrom', model.CityState).find().should.eventually.have.length.be(1)

      it 'should include instances of shallow sub classes when querying for a model class', ->
        building = new model.Building('building').save()
        office = new model.Office('office').save()
        house = new model.House('house').save()

        Promise.all([building, office, house]).then(->
          new Weaver.ModelQuery(model)
          .class(model.Building)
          .find()
        ).then((res)->
          houseFound = false
          officeFound = false
          res.map((n)->
            if n.id() is 'house'  then houseFound = true
            if n.id() is 'office' then officeFound = true
          )
          assert.equal(houseFound, true)
          assert.equal(officeFound, true)
        )

      it 'should include instances of deep sub classes when querying for a model class', ->
        new Weaver.ModelQuery(model)
        .class(model.Construction)
        .find().then((res)->
          officeFound = false
          res.map((n)->
            if n.id() is 'office' then officeFound = true
          )
          assert.equal(officeFound, true)
        )

      it 'should query correctly for model instances with multiple classes', ->
        new Weaver.ModelQuery(model)
        .class(model.Office)
        .find().then((res)->
          assert.equal(res[0].id(), 'basshouse')
        ).then(->
          new Weaver.ModelQuery(model)
          .class(model.House)
          .find()
        ).then((res)->
          bassFound = false
          res.map((n)->
            if n.id() is 'basshouse' then bassFound = true
          )
          assert.equal(bassFound, true)
        )

      it 'should correctly find the constructor for multi range', ->
        new Weaver.ModelQuery()
        .class(model.Person)
        .restrict('personD')
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          p = instances[0]

          assert.equal(p.constructor, model.Person)
          assert.equal(p.id(), 'personD')
          assert.equal(p.relation('comesFrom').all().length, 2)
          for to in p.relation('comesFrom').all()
            if to.id() is 'Netherlands'
              expect(to).to.be.instanceOf(model.Country)
              p.getToRanges('comesFrom', to).should.eql(['test-model:Country'])
            else if to.id() is 'test-model:Rotterdam'
              expect(to).to.be.instanceOf(model.City)
              p.getToRanges('comesFrom', to).should.eql(['test-model:City'])
            else
              assert.fail(undefined, undefined, "Unexpected to: #{to.id()}")
        )

      it 'should correctly find the constructor for ambivalent multi range', ->
        new Weaver.ModelQuery()
        .class(model.Person)
        .restrict('person人物')
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          p = instances[0]

          assert.equal(p.constructor, model.Person)
          assert.equal(p.id(), 'person人物')
          assert.equal(p.relation('comesFrom').all().length, 3)
          for to in p.relation('comesFrom').all()

            if to.id() is 'HongKong'
              expect(to).to.be.instanceOf(Weaver.Node)
              p.getToRanges('comesFrom', to).should.have.members(['test-model:Country', 'test-model:City'])

              (def.id() for def in to.relation('rdf:type').all())
              .should.have.members(['test-model:Country', 'test-model:City'])
              (def.id() for def in hongkong.nodeRelation('rdf:type').all())
              .should.have.members(['test-model:Country', 'test-model:City'])

            else if to.id() is 'Spain'
              expect(to).to.be.instanceOf(model.Country)

            else if to.id() is 'test-model:Rotterdam'
              expect(to).to.be.instanceOf(model.City)

            else
              assert.fail(undefined, undefined, "Unexpected to: #{to.id()}")
        )

      it 'should correctly find the constructor for subs of range', ->
        autograph = new model.td.Autograph('passport')
        passport = new model.Passport('passport')
        autograph.relation('carbonCopy').add(passport)

      it 'should correctly find the constructor for range with only one correct option', ->
        new Weaver.ModelQuery()
        .class(model.Person)
        .restrict('personBas')
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          p = instances[0]

          assert.equal(p.constructor, model.Person)
          assert.equal(p.id(), 'personBas')
          for to in p.relation('livesIn').all()
            assert.equal(to.id(), 'basshouse')
            expect(to).to.be.instanceOf(model.House)
          for to in p.relation('worksIn').all()
            assert.equal(to.id(), 'basshouse')
            expect(to).to.be.instanceOf(model.Office)
          for to in p.relation('signed').all()
            if to.id() is 'basDeliveryOrder'
              expect(to).to.be.instanceOf(model.DeliveryNotice)
            if to.id() is 'basContract'
              expect(to).to.be.instanceOf(model.td.Document)
        )

      it 'should support mixing classes from main model and included models', ->
        new Weaver.ModelQuery()
        .class(model.td.Document)
        .hasRelationIn('Person.signed', personBas)
        .find()
        .then((instances) ->
          assert.equal(instances.length, 2) # [ Document, DeliveryNotice ]
          expect(instances[0]).to.be.instanceOf(model.td.Document)
        )

      it 'should support dot referencing class from included models', ->
        new Weaver.ModelQuery()
        .class(model.td.Clerk)
        .hasRelationOut('Person.comesFrom')
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          expect(instances[0]).to.be.instanceOf(model.td.Clerk)
        )

      it 'should support setting reference context', ->
        new Weaver.ModelQuery(model.td)
        .class(model.td.Clerk)
        .hasRelationOut('Person.comesFrom')
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          expect(instances[0]).to.be.instanceOf(model.td.Clerk)
        )

      it 'should query inside referenced context plain', ->
        new Weaver.ModelQuery(model)
        .class(model.td.Clerk)
        .hasRelationOut('td.Clerk.authorised')
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          expect(instances[0]).to.be.instanceOf(model.td.Clerk)
        )

      it 'should query inside referenced context reversed', ->
        new Weaver.ModelQuery(model.td)
        .class(model.td.Clerk)
        .hasRelationOut('Clerk.authorised')
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          expect(instances[0]).to.be.instanceOf(model.td.Clerk)
        )

      it 'should query inside referenced context implicit', ->
        new Weaver.ModelQuery(model)
        .class(model.td.Clerk)
        .hasRelationOut('Clerk.authorised')
        .find()
        .then((instances) ->
          assert.equal(instances.length, 1)
          expect(instances[0]).to.be.instanceOf(model.td.Clerk)
        )

      it 'should do a hasRelationOut sub model query', ->
        new Weaver.ModelQuery(model)
        .class(model.Person)
        .hasRelationOut('Person.comesFrom', new Weaver.ModelQuery(model).class(model.Country))
        .find()
        .then((instances) ->
          assert.equal(instances.length, 3)
        )

      it 'should warn if hasRecursiveRelationIn is given a sub model query', ->
        query = new Weaver.ModelQuery(model)
        .class(model.td.Document)
        assert.throws(->query.hasRecursiveRelationIn('Person.signed', new Weaver.ModelQuery().class(model.td.Document)))

      it 'should load selectIn using proper model class', ->
        new Weaver.ModelQuery(model)
        .restrict('basshouse')
        .selectIn('*')
        .first()
        .then((node)->
          for building in node.relationsIn.livesInSomeBuilding.nodes
            building.should.be.instanceOf(model.Building)
          for company in node.relationsIn.worksIn.nodes
            company.should.be.instanceOf(model.Company)
        )
        
  it 'should remove the model from the query when using \'destruct\' function', ->
    q = new Weaver.ModelQuery(model)
    expect(q.model).to.be.not.undefined
    q.destruct()
    expect(q.model).to.be.undefined

  it 'should get the correct database key for inherited attributes', ->
    q = new Weaver.ModelQuery(model)
    q.contains('Passport.fileName', 'someFilename')
    expect(q._conditions['hasFileName']).to.be.not.undefined
