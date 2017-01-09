[![Build Status](https://img.shields.io/travis/weaverplatform/weaver-sdk-js/develop.svg)](http://travis-ci.org/weaverplatform/weaver-sdk-js)[![codecov](https://img.shields.io/codecov/c/github/weaverplatform/weaver-sdk-js/develop.svg?maxAge=0)](https://codecov.io/gh/weaverplatform/weaver-sdk-js)[![Npm](https://img.shields.io/npm/v/weaver-sdk.svg)](https://www.npmjs.com/package/weaver-sdk)


# Weaver SDK for JavaScript
A library that gives you access to the Weaver platform from your JavaScript app.

## API

### Object: Weaver

##### Initialize
- weaver = new Weaver()
- weaver.connect(socketUrl)
- weaver.database(localDatabase)
- weaver.authenticate(token)

##### Interact
- weaver.add(data, type, id)
- weaver.addPromise(data, type, id): Same as weaver.add, but returns a promise which is fulfilled through the server.
- weaver.collection(data, id)
- weaver.get(id, {eagerness})

### Object: Entity

##### Read
- entity.$id()
- entity.$type()
- entity.$values()
- entity.$links()
- entity.$linksArray()
- entity.$isFetched({eagerness})
- entity.$fetch({eagerness})

##### Persist
- entity.$push(key, value)
- entity.$push(entity)
- entity.$remove(key)
- entity.$remove(entity)
- entity.$destroy()

##### Events
- entity.$on('key', callback)


## Examples

##### Creating a new Weaver instance connected to a socket
```javascript
var weaver = new Weaver();
weaver.connect('https://weaver-server.herokuapp.com');
```

##### Creating a new Weaver instance connected to a local database
```javascript
var weaver = new Weaver();
weaver.database(database);
```

##### Authenticating using a token

Authentication is optional (but enforced if the server is configured so)

```javascript
weaver.authenticate('token123')
```

Returns a promise with a javascript object containing information about whether the client is authorized to perform the following operations:
```javascript
{
  read: true,
  write: false
}

```
##### Creating an entity
```javascript
var john = weaver.add({name: 'John Doe', age: 27, male: true});
```

##### Getting an entity
```javascript
weaver.get('id_01', {eagerness: 1}).then(function(entity){
	...
});
```

##### Fetching an entity
```javascript
john.$fetch({eagerness: 3});
```

##### Updating an entity
```javascript
john.color = 'Red';
john.$push('color');
```

###### or
```javascript
john.$push('color', 'Red');
```

##### Linking to another entity
```javascript
john.friend = lisa;
john.$push('friend');
```

###### or
```javascript
john.$push('friend', lisa);
```

##### Linking to multiple entities
```javascript
john.friends = weaver.collection();
john.$push('friends');
john.friends.$push(lisa)
```

###### or
```javascript
john.friends.$push(lisa.id(), lisa);
```

###### or
```javascript
john.friends[lisa.id()] = lisa;
john.friends.$push(lisa.id());
```

##### Removing entity key
```javascript
john.age = '28';
john.$remove('age');
```

###### or
```javascript
john.friend = lisa;
john.$remove('friend');
```

##### Destroying an entity
```javascript
john.$destroy();
```

## Install - Development

`$ npm install`

If you want to add weaver-sdk-js to your webApp, use [grunt](http://gruntjs.com/) to create the js. Two main commands.

For production environments:

`$ grunt dist`

For development environments:

`$ grunt dev`




## Todo
- further implement local listening and removing
- error handling
- repository weaver under $
- add more tests

## Future work
- fetch incoming links
- add created and updated metadata
- add date field
- enable paging
- authentication
- querying data
