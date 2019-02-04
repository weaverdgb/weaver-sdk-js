# Changelist

## 11.3.2
- Include dist file second try

## 11.3.1
- Include dist file

## 11.3.0
- Add getters and setters for WeaverQuery to keep the result set open
- Add route to close a connection that was kept open
- Add Weaver.Transaction() and support of transaction usage in Weaver.Query
  and sending write operations
- Introduce a new way of querying the database: [Sparql Query](https://github.com/weaverplatform/weaver-docs/blob/master/pages/developers/reference/weaver-sdk-js.md#weavernarql)

## 11.2.1
- Fixes selectRecursiveOut calls for ModelQueries with multiple arguments
- Fixes alwaysLoadRelation calls for ModelQueries

## 11.2.0
- Adding more test to validate id names on creating projects
- Adding test to validate id names on cloning projects
- Added created by constraint to weaver query
- Fix checking value for date. Don't throw error on js Date objects

## 11.1.2
- When updating a relation, add newNode if oldNode is undefined

## 11.1.1
- Fix for Weaver not being set on the window object
- Add isAllowedRelation function to verify relation key on model class

## 11.1.0
- Throw a descriptive error when no model is supplied as agument for a ModelQuery
- SDK supports React Native when doing require('weaver-sdk/react-native')

## 11.0.2
- Fix bug in allowed relations when two different modelKeys map to the same key

## 11.0.1
- Fixes bug in bootstrapping another project

## 11.0.0
- Switch to moment js for supporting dates and related data types

## 10.0.0
- Remove nodes and relationNodes on relation
- Changed model class comparison to evaluate against constructor name,
  instead of doing object comparison between the two constructors
  (wasn't otherwise able to use multiple references to the same model)
- Add the relation('link').only(to) call
- Adds WeaverNodeList
- Rewrite relation load without possibility or need to set preferred constructor
- Implement relation onlyOnce
- Completely promisify bootstrap function

## 9.1.0
- Add wpath support with initial two filters.

## 9.0.0
- Adds Weaver.ModelClass.getSuperClass() method.
- Changes Weaver.ModelQuery().prototype.class() method to return valid for
  all subclasses of a model class, as well as the class itself.

## 8.11.1
- Use a getter function for fs so it doesnt fail when not required.

## 8.11.0
- Read default data type for attributes from model.

## 8.10.0
- Add function to get data type of attribute.

## 8.9.0
- Adds propagate-delete functionality (incl propagationDepth).
- Load init instances on Model Context without the need to call bootstrap.

## 8.8.0
- Warn if a user tries to give a sub ModelQuery to a recursive condition.
- Add unlimited query.

## 8.7.0
- Replace model inclusion of models into one model with one classList
  for simplified and more powerfull usage (e.g. ModelQuery crossing
  model inclusion hops).
- Use a DefinedNode for constructing init block members of a model.

## 8.6.2
- Rewrite init code for model for 8.6.1 version.

## 8.6.1
- Remove level-fs dependency.
- Added the test proposed by Michiel for limiting ordered queries.
- Allow one model instances to be in the init block of more then
  one class in a model.

## 8.6.0
- Rewritten subclassing mechanism of ModelClass.
- Allow specifying graph in load function on ModelClass.
- When attributes is an array, return the first instead of the array.
- Let the Legacy Error object be a JS Error instead just a {} object.

## 8.5.0
- Allows a Constructor function to be passed to Weaver.Relation.prototype.load.
- Implements selectRelation for Weaver.ModelQuery.
- Implements Weaver.ModelRelation.prototype.load (with validity checking).

## 8.4.0
- Add createdAt and createdBy methods to weaver node.
- Adds try/catch to JSON.parsing in cm.prototype.query.

## 8.3.0
- Adds the selectIn method on WeaverQuery, which allows you to load any
  incoming relations if they are present.

## 8.2.1
- Mention id and graph of node not found message.

## 8.2.0
- If first a model is bootstrapped and then another model is bootstrapped
  that includes the first a node was not found.
- Send existing nodes to cascading bootstraps to effectuate fix.
- Only look in the graph with the model version for already existing nodes.

## 8.1.0
- Adds the selectRelations(..) function to WeaverQuery. If this is called only
  relations matching the argument keys are returned from the server. This
  should limit result set sizes and thus improve processing performance.

## 8.0.0
- Only use major model version in graph name for bootstrap.

## 7.3.1
- Set target project in booststrap query.

## 7.3.0
- Set target project in booststrap write operations.

## 7.2.3
- Add project argument to bootstrap function.

## 7.2.2
- Fixes model classes not being able to unset attributes.

## 7.2.0

- Adding a general method to store metadata related with a project.
- Removing the previous method to add metadata for projects related only with Apps.

## 7.1.0
- Updates README.
- Removes broken weaver.getUsersDB method.
- Update minio in docker composition to the lates release version.

## 7.0.0
- Moves to coffeescript 2.

## 6.5.1
- Fixes a bug in the required versions.

## 6.5.0
- Adds redirectGraph operations, which redirects relations to a graph from
  a graph to a different graph.

## 6.4.9
- In some situations with pointing to super clases the model did not load
  ranges properly.

## 6.4.8
- Throw an error when doing an empty array restrict on WeaverQuery

## 6.4.6
- Do not use the id of the node as identifier in cycle detection for
  collecting the pending writes
- The ModelClass .nodeGet and .nodeSet did not work

# 6.4.5
- Put member relationship of new modelclass instance in the instance graph,
  not in the model graph

## 6.4.4
- Fixes race condition in WeaverRelation.remove, it now correctly returns
  a promise again
- Fixed a bug related to inherited attribute keys in map function for models

## 6.4.3
- Do not throw an error on unmet minimal cardinality on model relations
- Allow to have model class nodes instances be a member some other class, so
  they a have normal id without colon
- Replaces errors for required attributes, min relations and max relations with warnings

## 6.4.2
- Look in all graphs to find membership etc. relations of model classes
- Reason from the right graph when selecting super classes in the model

## 6.4.1
- Overload allowed attributes and relations from included models
- Allow setting a subclass from an included model of a range

## 6.4.0
- WeaverRelationNodes now have their source, target, and key set when loaded from weaver query
- WeaverProject now have an operation to truncate a graph

## 6.3.5
- Fixes running bootstrap twice with some nodes previously missing

## 6.3.3
- Fixes ModelClass instances raising an exception when being asked about an
  attribute they don't have, instead undefined is returned

## 6.3.2
- Fixes a bug where calling load() on an instance of ModelClass would destroy
  the ModelClass functions

## 6.3.1
- Bugfix checking range when creating relation to member of included models.

## 6.3.0
- Allow models to include models.
- Add snapshotGraph calls next to snapshot for full project.
- Adds Model.list method
- Adds ability to send files to plugins

## 6.1.5
- Fixes an issue where membership or subtype relations would not be accepted by
  the model.

## 6.1.4
- Instances from any ModelClass extension should not be put in the model
  graph. By default in the default graph, or set with argument.

## 6.1.3
- Do not consider e.g. owl:Class node a valid range for selecting the right
  constructor in processing a ModelQuery resultset.
- Instances from any ModelClass extension should not be put in the model
  graph. By default in the default graph, or set with argument.

## 6.1.2
- Load already existing instances from the init block of a Model (now for
  real)

## 6.1.1
- Add missing check in add() on WeaverRelation for not creating writeops
- Load already existing instances from the init block of a Model

## 6.1.0
- Adds `weaver.disconnect()` function to close the socket connection
- Adds support for checking the existence of nodes
- Adds support to query for WeaverModel init members using model.InitMember, so
  `model.City.Rotterdam` is now supported instead of first having to look up the
  `model.City` instance.
- Adds identityString to Weaver.Node to return the graph:nodeid combination
- Add `model.City.addMember(node)` for adding an existing node to a model
- Allow nodes to be member of multiple WeaverModel's
- Fixes freeze and unfreeze persistence after weaverServer reboot
- Adds feature to read the freeze or unfreeze state of a project by isFrozen
	```coffeescript
	weaver.currentProject().isFrozen()
	.then((res)->
		console.log res.status
	)
	```
- Posible to add app metadata for a project `addApp(name,metadata)`
	```coffeescript
	p = weaver.currentProject()
	appMetadata =
		appName: 'FooBarApp'
		appVersion: '0.2.1-fooBar-b'
		desireSDK: '6.0.1-weaver'
	p.addApp(appMetadata.appName,appMetadata)
	```
	- removeApp still the same, just pass the appName to remove it

## 6.0.1
- Fixes a bug where the weaver-server embedded sdk would not send GET request
  bodies
