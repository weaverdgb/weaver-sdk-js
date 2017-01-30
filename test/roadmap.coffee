mo = new Weaver.Node()

# Set fields
mo.set('name', 'Mohamad')
mo.set('age', 29)
mo.set('male', true)
mo.save().then((n)-> ).catch((error)->)

# Or
mo.save({'married': true})

# Use
console.log(mo.get('age'))

# Built in and can't be set
console.log(mo.nodeId) # Or console.log(mo.id())
console.log(mo.createdAt)
console.log(mo.updatedAt)

# Refresh from server
mo.fetch().then((mo)->)

# Load from server
Weaver.Node.get("idOfMo").then((mo)->)

# Update
mo.set('name', 'Mohamad Alamili')
mo.save() # Only 'dirty' fields are sent to server

# Delete single field
mo.unset('age')
mo.save()

# Destroy
mo.destroy()

# Add relations
Node son = new Weaver.Node()
son.save({name: 'Tobi'})

relation = mo.relation('hasSon')
relation.add(son)
mo.save()

# Remove relation
relation.remove(son)
mo.save()

# By default, the list of objects in this relation are not downloaded.
# You can get them using Weaver.Query
relation.query().find().then((list) ->)

# Or
query = relation.query()
query.equalTo("name", "Tobi")
query.find().then((list) ->)

# Querying
# Create a Weaver.Query object, put conditions on it, and then retrieve an Array of matching Weaver.Nodes using find.
query = new Weaver.Query()
query.equalTo("hasName", "Mohamad")
query.notEqualTo("male", false)
query.containedIn("lastName", ["Al Amili", "Alamili", "Amili"])   # Or notContainedIn
query.greaterThan("age", 20)
query.exists("rdfType")   # If it has this relationship, or query.doesNotExist()
query.lessThanOrEqualTo("age", 30);
query.startsWith("middleName", "Jaffar");  # Various string queries possible, endsWith, etch
query.limit(10)
query.skip(5)     # Useful for pagination
query.ascending("age")  # Or descending
query.select("age", "hasName"); # Limit the fields to get fetched (remaining can get fetched using .fetch())
query.find().then((results)->)

# To count, use query.count() instead of find()
query.count().then((number)->)


# Chain queries by using matchesKeyInQuery
# Example: Find all persons aged above 25 and living in a City with population below 20.000
cityQuery = new Weaver.Query()
cityQuery.lessThan("population", 20000)

personQuery = new Weaver.Query()
personQuery.greaterThan("age", 25)
personQuery.matchesKeyInQuery("livingIn", "name", cityQuery);
personQuery.find()

# Same works for relations, using matchesQuery and matchesReverseQuery for incoming relations
# Example, find all friends to people living in Delft of which firstname starts with Di
cities = new Weaver.Query()
cities.equals("name", "Delft")

friends = new Weaver.Query()
friends.equals("type", new Weaver.Node("Friend"))
friends.startsWith("name", "Di")
friends.matchesQuery('livingIn', cities)
friends.find()

# Combine queries with or
query1  = new Weaver.Query()
query2  = new Weaver.Query()
orQuery = Weaver.Query.or(quer1, query2)
orQuery.find()

# Real use case example:
# Find all afsluitbomen located at a place that is maintained by employees starting with name Sa
# So x -> (maintains) location <- (is located at) afsluitboom

employees = new Weaver.Query()
employees.startsWith("name", "Sa")

locaties = new Weaver.Query()
locaties.matchesReverseQuery("is maintained by", employees)

afsluitbomen = new Weaver.Query()
afsluitbomen.equals("rdf:type", new Weaver.Node("lib:Afsluitboom"))
afsluitbomen.matchesQuery("is located at", locaties)
afsluitbomen.find()



# Authentication
Weaver.User.logIn('asdf', 'zxcv').then((user) ->

  # Get all projects that current user has access to
  projects = Weaver.Project.all()

  # Use the first one
  Weaver.useProject(projects[0])

  # Can not save node
  node = new Weaver.Node()
  node.save().then().catch((error) ->
    switch error.code
      when WeaverError.NO_WRITE_PERMISSION then return
  )

  # Can not read node
  Weaver.Node.get('abc').then().catch((error) ->
    switch error.code
      when WeaverError.NO_READ_PERMISSION then return
  )



)
