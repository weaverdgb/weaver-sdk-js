# Weaver SDK for JavaScript
A library that gives you access to the Weaver platform from your JavaScript app.

## API

### Object: Weaver
- weaver.add(data, type, id)
- weaver.get(id, {eagerness})

### Object: Entity

##### Read
- entity.id()
- entity.type()
- entity.links()
- entity.values()
- entity.isFetched({eagerness})
- entity.fetch({eagerness})

##### Save
- entity.push(key, value)
- entity.push(entity)
- entity.remove(key)
- entity.remove(entity) 
- entity.destroy()


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

##### Fetching an entity
```javascript
john.fetch({eagerness: 3});
```

##### Updating an entity
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


## Todo
- repository weaver under $
- add more tests

## Future work
- add created and updated metadata
- add date field
- enable paging
- fetch incoming links
- authentication
- querying data
