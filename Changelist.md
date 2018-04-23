# Changelist

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
