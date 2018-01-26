# Changelist

## 6.0.1
- Fixes a bug where the weaver-server embedded sdk would not send GET request
  bodies

## 6.1.0-beta
- Add support for Check existence of nodes
- Adds support to query for WeaverModel init members using model.InitMember, so
  `model.City.Rotterdam` is now supported instead of first having to look up the
  `model.City` instance.
