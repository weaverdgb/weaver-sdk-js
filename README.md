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
		<a href="https://gitter.im/weaver-platform/weaver-sdk-js"><img src="https://img.shields.io/gitter/room/nwjs/nw.js.svg" alt="Gitter" /></a>
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

This readme covers development documentation, for usage documentation, see:
[weaver-docs](https://github.com/weaverplatform/weaver-docs)

## Docker composition

To get a weaver installation up and running, use the following command:
```
docker-compose -f test-server/docker-compose.yml up
```
This starts a weaver-server, database-connector, and file storage (minio)
container which the SDK can connect to and perform operations on.

## Install dependencies

```
$ yarn
```

## Run tests

Please note that these require a running weaver installation (such as provided
by the docker composition), and the contents of that installation will be wiped
as part of the test run.

```
$ yarn test
```

## Coding style

Follow the [sysunite coffeescript style
guide](https://github.com/sysunite/coffeescript-style-guide)

