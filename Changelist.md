# Changelist

## 6.0.1
- Fixes a bug where the weaver-server embedded sdk would not send GET request
  bodies

## 6.1.0-beta
- Adds `weaver.disconnect()` function to close the socket connection
- Adds support for checking the existence of nodes
- Adds support to query for WeaverModel init members using model.InitMember, so
  `model.City.Rotterdam` is now supported instead of first having to look up the
  `model.City` instance.
- Adds identityString to Weaver.Node to return the graph:nodeid combination
- Add `model.City.addMember(node)` for adding an existing node to a model
- Allow nodes to be member of multiple WeaverModel's