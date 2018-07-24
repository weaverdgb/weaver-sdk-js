# Changelist

## 8.6.1
- Remove level-fs dependency.

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
