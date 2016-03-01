# weaver-sdk-js
Weaver SDK for JavaScript

## API

### Class: Weaver
- weaver.add(data, type, id)
- weaver.get(id, {eagerness})

### Class: Entity

##### Read
- entity.id()
- entity.type()
- entity.links()
- entity.values()
- entity.isFetched({eagerness})

##### Sync
- entity.fetch({eagerness})
- entity.push(key, value)
- entity.remove(key)
- entity.destroy()

##### Convenience
- entity.remove(entity) for entity.remove(entity.id(), entity)
- entity.push(entity) for entity.push(entity.id(), entity)


## Examples

##### Creating a new Weaver instance
```javascript
var weaver = new Weaver('https://weaver-server.herokuapp.com');
```

##### Creating an entity
```javascript
var john = weaver.entity({name: 'John Doe', age: 27, male: true});
```

##### Loading an entity
```javascript
var lisa = null;
weaver.load('cil9cvoae00003k6mz1mvt3gz', {eagerness: 1}).then(function(entity){
  lisa = entity;
});
```

##### Fetching entity
```javascript
john.fetch({eagerness: 3});
```

##### Updating entity
```javascript
john.color = 'Red';
john.push('color');
```

###### or
```javascript
john.push('color', 'Red');
```

##### Linking to another entity
```javascript
john.friend = lisa;
john.push('friend');
```

###### or
```javascript
john.push('friend', lisa);
```

##### Linking to multiple entities
```javascript
john.friends = weaver.add();
john.friends.push(lisa)
```

###### or
```javascript
john.friends.push(lisa.id(), lisa);
```

###### or
```javascript
john.friends[lisa.id()] = lisa;
john.friends.push(lisa.id());
```


## TODO
- repository weaver under $
- refactor
- restructure tests

## Future work
- created and updated metadata
- date field
- paging
- incoming links
- auth
- querying