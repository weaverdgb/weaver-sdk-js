<div align="center">
  <br />
  <p>
    <a href="http://weaverplatform.com"><img
		width="350px" src="icon.png" alt="weaver" /></a>
  </p>
  <br />
  <p>
    <a href="https://www.npmjs.com/package/weaver-sdk"><img src="https://img.shields.io/npm/v/weaver-sdk.svg?maxAge=3600" alt="NPM version" /></a>
    <a href="https://www.npmjs.com/package/weaver-sdk"><img src="https://img.shields.io/npm/dt/weaver-sdk.svg?maxAge=3600" alt="NPM downloads" /></a>
		<a href="https://codecov.io/gh/weaverplatform/weaver-sdk-js"><img src="https://img.shields.io/codecov/c/github/weaverplatform/weaver-sdk-js/develop.svg?maxAge=0" alt="Code coverage" /></a>
    <a href="https://travis-ci.org/weaverplatform/weaver-sdk-js"><img src="https://travis-ci.org/weaverplatform/weaver-sdk-js.svg" alt="Build status" /></a>
    <a href="https://david-dm.org/weaverplatform/weaver-sdk-js"><img src="https://img.shields.io/david/weaverplatform/weaver-sdk-js.svg?maxAge=3600" alt="Dependencies" /></a>
  </p>
  <p>
    <a href="https://nodei.co/npm/weaver-sdk/"><img src="https://nodei.co/npm/weaver-sdk.png?downloads=true&stars=true" alt="NPM info" /></a>
  </p>
</div>


# Weaver SDK for JavaScript
A library that gives you access to the Weaver platform from your JavaScript app.

* [Getting started](#getting-started)
  + [Weaver](#weaver)
  + [Weaver.Nodes](#weavernodes)
* [Reference](#reference)
  + [Weaver](#weaver-1)
    - [Class Methods](#class-methods)
    - [Instance methods](#instance-methods)
  + [Weaver.Node](#weavernode)
    - [Class methods](#class-methods)
    - [Instance methods](#instance-methods-1)
* [Install - Development](#install---development)
* [Tests](#tests)
  + [NodeJS test](#nodejs-test)
  + [Browser test](#browser-test)
* [Todo](#todo)
* [Future work](#future-work)
- [Weaver Model](#weaver-model)
* [Creating](#creating)
    - [Step 1: Define a model](#step-1--define-a-model)
    - [Step 2: Instantiate a member](#step-2--instantiate-a-member)
  + [Step 3: Nest models to describe complex structures](#step-3--nest-models-to-describe-complex-structures)


## Getting started

### Weaver

Installation:
```
npm i -S weaver-sdk
```

Create the instance
```coffeescript
Weaver = require('weaver-sdk')
weaver = new Weaver()
```

Be sure to only create a single `Weaver` instance. If you need to get a reference to a previously instantiated `Weaver` instance later, or within devtools, just do:
```coffeescript
weaver = Weaver.getInstance()
```

Connect to a running weaver-server
```coffeescript
weaver.connect('http://my-weaver-server-url.com')
.then(->
  ...
```

Sign in with an existing user account for your weaver-server (or `admin : admin` if you've just cloned a weaver-server and there are no accounts yet)
```coffeescript
weaver.signInWithUsername('admin','admin')
.then(->
  ...
```

Select or create a new Project

```coffeescript
# select an existing project
Weaver.Project.list().then((projects)->
  weaver.useProject(projects[0])
)

# .. or create
p = new Weaver.Project(projectName, projectId)
p.create() # Required. Spins up a new database on weaver-server, which will forevermore be linked with this Weaver.Project
.then(->
  weaver.useProject(p)
  ...
```

You have now:
  - [x] Instantiated weaver
  - [x] Connected to a running server
  - [x] Signed-in with a valid user account
  - [x] Selected a project to work on

You're ready to start creating and interacting with nodes.

### Nodes

```coffeescript
# creates a node (only client side for now)
n = new Weaver.Node('hello-weaver')
n.id()
# -> 'hello-weaver'
```
```coffeescript
# set a name attribute
n.set('name', 'The First Node')
...
n.get('name')
# -> 'The First Node'
```
```coffeescript
# create a relation
o = new Weaver.Node('how-are-you-weaver')
o.set('name', 'The Second Node')
n.relation('hasDescendant').add(o)
```
```coffeescript
# getting relations
n.relation('hasDescendant')
# this returns a Weaver.RelationNode, which has a bunch of properties, among them a 'nodes' array, which contains all the nodes which are linked from the node 'n' via the relation 'hasDescendant'

n.relation('hasDescendant').first()
# -> returns the first relation for this relation key, in this case, the Weaver.Node object referenced by o

# gets the name attribute of the first relation from 'n' for the relation key 'hasDescendant'
n.relation('hasDescendant').first().get('name')
# -> 'The Second Node'
```
```coffeescript
# saving to db
n.save()
.then(->
  ...
# this collects all the pending writes on the node n, and pushes them to the database.
```
In our example, calling `n.save()` will execute several write operations on the database:
- a create node operation for node `n`
- a create attribute operation for the `name` attribute we set for `n`
- a create relation operation for node `n` to node `o`, using the relation key `hasDescendant`

In addition, `Weaver.Node.prototype.save` is downwards recursive, so it will collect and execute all pending writes on all relations of `n`, and all relations of those nodes, etc.
So, calling `n.save()` in our example above, will also collect and execute the pending write operations on node `o`:
- a create node operation for node `o`
- a create attribute operation for the `name` attribute we set for `o`

, as `o` is a relation of `n`. Pretty sweet, right?

```coffeescript
# loading saved nodes from the database
Weaver.Node.load('hello-weaver')
.then((node)->
  node.get('name')
)
# -> 'The First Node'
```
```coffeescript
  # nodes are loaded with a depth/eagerness of 1
  # relations will therefore need to be loaded explicitly
  Weaver.Node.load('hello-weaver')
  .then((node)->
    node.relation('hasDescendant').first().get('name')
    # -> undefined

    node.relation('hasDescendant').first().load()

  ).then((o)->
    o.get('name')
    # -> 'The Second Node'
  )

```


## Reference

### Weaver
#### Class Methods
```coffeescript
  Weaver.getInstance()
  # return the weaver instance
```
```coffeescript
  Weaver.useModel(model)
  # set's the Weaver.Model to be used by default
```
```coffeescript
  Weaver.currentModel()
  # returns the current default model
```
```coffeescript
  Weaver.shout(message)
  # Shout a message to other connected clients
```
```coffeescript
  Weaver.sniff(callback)
  # Listen to shouted messages and perform the supplied callback
```

```coffeescript
  Weaver.subscribe(operationType, callback)
  # Listen perform the supplied callback when events of the provided type are published to the server
  subscription = Weaver.subscribe('node.created', (msg, node) ->
    if node.id() is 'hello-world'
      console.log 'hello-weaver'
  )

  new Weaver.Node('hello-world')

  # -> 'hello-weaver'
```
```coffeescript
  Weaver.unsubscribe(subscription)
  # Unsubscribe from a specific subscription
```
```coffeescript
  Weaver.clearAllSubscriptions()
  # Unsubscribe from all subscriptions
```
#### Instance methods
```coffeescript
  Weaver.prototype.version()
  # returns sdk version
```
```coffeescript
  Weaver.prototype.serverVersion().then(console.log)
  # logs version of connected server
```
```coffeescript
  Weaver.prototype.connect(endpoint)
  # sets endpoint of weaver-server to connect to
```
```coffeescript
  Weaver.prototype.disconnect()
  # breaks connection with weaver-server, if connected to one
```
```coffeescript
  Weaver.prototype.useProject(project)
  # sets current project to read from/write to
```
```coffeescript
  Weaver.prototype.currentProject()
  # returns the current project
```
```coffeescript
  Weaver.prototype.signOut()
  # signs out the current user
```
```coffeescript
  Weaver.prototype.currentUser()
  # returns the currently signed-in user
```
```coffeescript
  Weaver.prototype.signInWithUsername(username, password)
  # retrieves a user token, and a user object.
```
```coffeescript
  Weaver.prototype.signInWithToken(authToken)
  # signs in a user using a token retrieved from the server
```
```coffeescript
  Weaver.prototype.wipe
  # wipes:
  #   - all projects on the server
  #   - all user data on the server
```

### Weaver.Node
#### Class methods
```coffeescript
  new Weaver.Node(nodeId, graph)
  # creates a new Weaver.Node, don't forget to call `save` to persist to db
```
```coffeescript
  Weaver.Node.load(nodeId)
  # returns a Promise which will resolve the specified node if it exists
```
```coffeescript
  Weaver.Node.get(nodeId)
  # creates a shallow Node with the specified id
  # note: does not create a create.node operation in pendingWrites, so node.save() will not push a node creation operation to the server.
  # not recommended unless you know what you're doing, use Weaver.Node.load instead
```
```coffeescript
  Weaver.Node.firstOrCreate(nodeId)
  # gets the node matching the id if it exists, or constructs a new node with the specified id
```
```coffeescript
  Weaver.Node.batchSave(array)
  # pass an array of nodes with pendingWrites to save them all at once with a single server transaction
```
```coffeescript
  Weaver.Node.batchDestroy(array)
  # pass an array of nodes to destroy them all at once with a single server transaction
```
#### Instance methods
```coffeescript
  Weaver.Node.prototype.load()
  # same as Weaver.Node.load(Weaver.Node.prototype.id())
```
```coffeescript
  Weaver.Node.prototype.id()
  # returns the id of a node
```
```coffeescript
  Weaver.Node.prototype.attributes()
  # returns a map of loaded attributes on this node
```
```coffeescript
  Weaver.Node.prototype.relations()
  # returns a map of loaded relations on this node
```
```coffeescript
  Weaver.Node.prototype.set(key, value)
  # sets an attribute on the node
```
```coffeescript
  Weaver.Node.prototype.unset(key)
  # unsets an attribute on the node
```
```coffeescript
  Weaver.Node.prototype.get(key)
  # gets the value for a given attribute key on the node
```
```coffeescript
  Weaver.Node.prototype.relation(key)
  # returns a Weaver.Relation for the given relation key
  # note, creates an empty Weaver.Relation object if no loaded relation are found.
```
```coffeescript
  Weaver.Node.prototype.clone(newId, relationsToTraverse...)
  # clones a node.
  # recursively clones relations of the node if relationsToTraverse is defined
```
```coffeescript
  Weaver.Node.prototype.equals(node)
  # checks if the supplied node refers to the same node as the instance from a database perspective (id comparison)
```
```coffeescript
  Weaver.Node.prototype.save()
  # executes all pending db writes on the instance
  # is recursively called on all loaded relations of this node
```
```coffeescript
  Weaver.Node.prototype.destroy()
  # destroys the instance, also on the db
```
### Weaver.Relation
#### Instance methods
```coffeescript
  Weaver.Relation.prototype.load()
  # loads all nodes on this relation, so they will no longer be shallow
```
```coffeescript
  Weaver.Node.prototype.to(node)
  # returns the relationNode linking to the passed node, or throws an error if no relationNode is present linking to the passed node
```
```coffeescript
  Weaver.Node.prototype.all()
  # returns all nodes linked to with the current relation key
```
```coffeescript
  Weaver.Node.prototype.first()
  # returns the first node linked to with the current relation key
```
```coffeescript
  Weaver.Node.prototype.add()
  # links to the passed node from the instance relation
```
```coffeescript
  Weaver.Node.prototype.remove(node)
  # unlinks the passed node from the relation instance
```
### Weaver.Project
#### Class methods
```coffeescript
  Weaver.Project.list()
  # Lists all projects on the server that the logged in user has access to.
```
#### Instance Methods
```coffeescript
  new Weaver.Project(@name, @projectId)
  # creates a new Weaver.Project clientside
```
```coffeescript
  Weaver.Project.prototype.create()
  # Publishes a create-project operation on the server.
  # Consider this as the persistent constructor
```
```coffeescript
  Weaver.Project.prototype.destroy()
  # Self-explanatory. This is a persisting operation.
```
```coffeescript
  Weaver.Project.prototype.wipe()
  # Wipes all data from this project, without deleting the project itself
```
```coffeescript
  Weaver.Project.prototype.freeze()
  # Freezes project in it's current state, preventing any further writing
```
```coffeescript
  Weaver.Project.prototype.unfreeze()
  # Unfreezes project, allowing writing as normal
```
```coffeescript
  Weaver.Project.prototype.isFrozen()
  # Return's the frozen state of this project
```
```coffeescript
  Weaver.Project.prototype.rename(name)
  # Renames this project on the server
```
```coffeescript
  Weaver.Project.prototype.clone()
  # Clone's this project in it's entirety
```
```coffeescript
  Weaver.Project.prototype.getSnapshot(shouldBeJson, shouldBeZipped)
  # Returns a snapshot of this project, defaults to zipped = false, shouldBeJson = true
```
```coffeescript
  Weaver.Project.prototype.clone()
  # Clone's this project in it's entirety
```
```coffeescript
  Weaver.Project.prototype.addApp(appName, appData)
  # Add some meta data to this project relating to a specific app
```
```coffeescript
  Weaver.Project.prototype.removeApp(appName)
  # Removes some meta data from this project relating to a specific app
```
```coffeescript
  Weaver.Project.prototype.getApps()
  # Returns a map which contains metadata for each app relating to this project, keyed by the app's name
```
### Weaver.User
#### Class Methods
```coffeescript
  Weaver.User.get(authToken)
  # create a shallow Weaver.User with aupplied userToken set
```
```coffeescript
  Weaver.User.list()
  # lists all users on the server
```
```coffeescript
  Weaver.User.listProjectUsers()
  # lists all users with access to the current project
```
#### Instance Methods
```coffeescript
  Weaver.User.prototype.id()
  # Returns the userId for the User instance
```
```coffeescript
  Weaver.User.prototype.save()
  # Persists user data to server
```
```coffeescript
  Weaver.User.prototype.changePassword(password)
  # Changes a user's password
```
```coffeescript
  Weaver.User.prototype.signUp()
  # Saves the user and signs in as currentUser
```
```coffeescript
  Weaver.User.prototype.destroy()
  # Destroys the user
```
```coffeescript
  Weaver.User.prototype.getProjectsForUser()
  # Returns the projects a user has access to
```
### Weaver.Query
#### Class methods
```coffeescript
  Weaver.Query.profile(callback)
  # Fires the callback whenever a query is resolved.
  # The callback is passed one argument, which contains information about the query which was just resolved
```
```coffeescript
  Weaver.Query.clearProfilers()
  # Destroys any notifiers which were created
```
#### Instance methods
```coffeescript
  Weaver.Query.prototype.find(Constructor)
  # Executes the query and returns results constructed with the supplied Constructor, if one is given
```
```coffeescript
  Weaver.Query.prototype.count()
  # Executes the query and returns a count of the results
```
```coffeescript
  Weaver.Query.prototype.first()
  # Executes the query and returns the first result
```
```coffeescript
  Weaver.Query.prototype.limit(limit)
  # Limits the amount of results (default/maximum permitted is 1,000)
```
```coffeescript
  Weaver.Query.prototype.skip(skip)
  # Skips the passed amount of results. Useful for Result pagination
```
```coffeescript
  Weaver.Query.prototype.order(keys, ascending)
  # Orders results based on their value for a given attribute key
```
##### Exclusion Criteria
```coffeescript
  Weaver.Query.prototype.restrict(nodes)
  # Adds a restriction on the query based on the ids of the array of passed nodes. (an array of ids is acceptable here too)
```
```coffeescript
  Weaver.Query.prototype.equalTo(key, value)
  # Restricts based on attributes. Results must match the passed key : value args
```
```coffeescript
  Weaver.Query.prototype.notEqualTo(key, value)
  # Restricts based on attributes. Results must not match the passed key : value args
```
```coffeescript
  Weaver.Query.prototype.startsWith(key, value)
  Weaver.Query.prototype.endsWith(key, value)
  # Restricts based on attributes. Results must have a value which matches the passed key, and which value matches the rule described.
```
```coffeescript
  Weaver.Query.prototype.lessThan(key, value)
  Weaver.Query.prototype.greaterThan(key, value)
  Weaver.Query.prototype.lessThanOrEqualTo(key, value)
  Weaver.Query.prototype.greaterThanOrEqualTo(key, value)
  # These all restrict based on attributes. The attribute value must respect the mathematical rule described
```
```coffeescript
  Weaver.Query.prototype.hasRelationIn(key, node...)
  Weaver.Query.prototype.hasNoRelationIn(key, node...)
  # These restrict based on incoming relations. key is the relation key, and node is the node which the relation must originate from. node is an optional argument here, if node is not passed, then this criteria is considered passed if ANY relation exists for the passed key.
```
```coffeescript
  Weaver.Query.prototype.hasRelationOut(key, node...)
  Weaver.Query.prototype.hasNoRelationOut(key, node...)
  # Same as above, but for outgoing relations instead
```
```coffeescript
  Weaver.Query.prototype.
  #
```
##### Extra loading instructions
```coffeescript
  Weaver.Query.prototype.selectOut(relationKeys...)
  # As above, but will recursively load
```
```coffeescript
  Weaver.Query.prototype.selectRecursiveOut(relationKeys...)
  # Will fully load outgoing relations with a relation key matching any one of the passed arguments
```
##### Nesting queries / FOAF
Any query which contains a node as an argument may instead be passed a nested query.
```coffeescript
  new Weaver.Query().hasRelationOut('hasChild',
    new Weaver.Query().hasRelationOut('attendsSchool', '*')
  )
  # will return all nodes which have an outgoing hasChild relation to a node which has an outgoing attendsSchool relation.
```
### Weaver Model

#### Creating

##### Step 1: Define a model


 This will create a new Model with the name 'Man'
 ```javascript
 manModel = new Weaver.Model("Man")
 ```
  This adds a new getter to any member of the 'Man' model. from now on, calling something like `manMember.get('name')`,
  will return the `object` of the triple `manMember -> hasName -> object`.
 ```javascript
 manModel.structure({
   name:"hasName"
 })
 ```
 The previous example added a getter for an attribute, to add a getter for a relation, you should prefix the predicate with an '@'
 ```javascript
  manModel.structure({
    name:"hasName"
    type:"@hasType"
  })
  ```
 Call `.setStatic()` on a model to set a static property for the model. Now, all members of the 'Man' model will already have the property `latinName` set to "Homo sapien" upon instantiation.
 In addition to this, the following triple will be inserted into any connected db ` manMember -> hasLatinName -> "Homo sapien" `.
 ```javascript
    manModel.structure({
      name:"hasName"
      type:"@hasType"
      latinName: "hasLatinName"
    })
    .setStatic("latinName", "Homo sapien")
 ```
 When you've finished describing your model, call `buildClass()` to get a constructor to initialize new members of that model.
 ```javascript
	Man = manModel.buildClass()
	trump = new Man()
 ```

##### Step 2: Instantiate a member

Model members extend `Weaver.Node`. They can be saved to the database, to be loaded later, and if their constructor is passed an argument,
The root node of that member will be initialized with that argument as an id.

 ```javascript
     typeModel = new Weaver.Model("Type")
     typeModel.structure({
       name:"hasLabel"
     })
     .save();
     Type = typeModel.buildClass();
     manType = new Type("lib:Man")
 ```

Dynamic properties for model members can be set with `.setProp(propKey, propVal)`. Use `setProp()` both for setting attributes and adding relations,
the model will figure out what to do based on the structure you provided earlier.

```
		manType.setProp("name", "The Type node for all men.")
		.save()
```

##### Step 3: Nest models to describe complex structures

Include a model member in the definition for another model.
```javascript
    manModel.structure({
      name:"hasName"
      type: ["@hasType", typeModel.id()]
      latinName: "hasLatinName"
    })
    .setStatic("latinName", "Homo sapien")
    .setStatic("type", manType)
 ```
 Now all man model members will be instantiated with a `hasType` relationship to the `manType` node
 (the one with id 'lib:Man', also the root of the `manType` model member).

 You can even chain getters together to return deep properties of a model member.
 ```javascript
    typeModel = new Weaver.Model("Type")
    typeModel.structure({
      name:"hasLabel"
    })
    .save();
    Type = typeModel.buildClass();
    manType = new Type("lib:Man")
    manType.setProp("name", "Type node for all men")

    manModel.structure({
      name:"hasName"
      type:["@hasType", typeModel.id()]
      latinName: "hasLatinName"
      nameOfType: "type.name"  //use a '.' to seperate path segments
    })
    .setStatic("latinName", "Homo sapien")
    .setStatic("type", manType)
    Man = manModel.buildClass()

    trump = new Man()
    trump.setProp("name", "Donald Drumpf")
    trump.get("name")         //returns "Donald Drumpf"
    trump.get("latinName")    //returns "Homo sapien"
    trump.get("type")         //returns WeaverModelMember instance
    trump.get("type.name")    //returns "Type node for all men"
    trump.get("nameOfType")   //returns "Type node for all men"

    trump.destroy()           //would that it were so easy..
 ```

## Building locally

```
$ git clone https://github.com/weaverplatform/weaver-sdk-js.git
$ npm i
$ npm run prepublish
```

## Tests

```
$ npm test
```
