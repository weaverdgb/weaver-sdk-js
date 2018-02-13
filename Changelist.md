# Changelist

## 6.1.5
- Fixes an issue where membership or subtype relations would not be accepted by
  the model.

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

