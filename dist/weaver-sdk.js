(function() {
  var Entity, cuid, isEntity, isObject, isReference,
    hasProp = {}.hasOwnProperty;

  cuid = require('cuid');

  isObject = function(object) {
    return Object.prototype.toString.call(object) === '[object Object]';
  };

  isReference = function(object) {
    return object['_REF'] != null;
  };

  isEntity = function(value) {
    return typeof value.$isEntity === 'function' && value.$isEntity();
  };

  module.exports = Entity = (function() {
    Entity.create = function(object) {
      var data, fetched, id, key, ref, type, value;
      type = object['_META'].type;
      fetched = object['_META'].fetched;
      id = object['_META'].id;
      data = object['_ATTRIBUTES'];
      if (data == null) {
        data = {};
      }
      if (object['_RELATIONS'] != null) {
        ref = object['_RELATIONS'];
        for (key in ref) {
          value = ref[key];
          data[key] = value;
        }
      }
      return new Entity(data, type, fetched, id);
    };

    Entity.build = function(object, weaver) {
      var entity, id, key, references, register, value;
      references = {};
      register = function(value) {
        var entity, key, results;
        entity = Entity.create(value).$weaver(weaver);
        references[entity.$id()] = entity;
        results = [];
        for (key in entity) {
          value = entity[key];
          if (key !== '$') {
            if (isObject(value) && (value['_REF'] == null)) {
              results.push(register(value));
            } else {
              results.push(void 0);
            }
          }
        }
        return results;
      };
      register(object);
      for (id in references) {
        entity = references[id];
        for (key in entity) {
          value = entity[key];
          if (key !== '$') {
            if (isObject(value)) {
              if (isReference(value)) {
                entity[key] = references[value['_REF']];
              } else {
                entity[key] = references[value._META.id];
              }
            }
          }
        }
      }
      return references[object._META.id];
    };

    function Entity(data, type, fetched, id) {
      var key, value;
      if (id == null) {
        id = cuid();
      }
      if (type == null) {
        type = '$ROOT';
      }
      if (fetched == null) {
        fetched = true;
      }
      this.$ = {
        id: id,
        type: type,
        fetched: fetched,
        listeners: {}
      };
      for (key in data) {
        value = data[key];
        this[key] = value;
      }
    }

    Entity.prototype.$id = function() {
      return this.$.id;
    };

    Entity.prototype.$type = function() {
      return this.$.type;
    };

    Entity.prototype.$values = function() {
      var key, value, values;
      values = {};
      for (key in this) {
        if (!hasProp.call(this, key)) continue;
        value = this[key];
        if (key !== '$' && key !== isEntity(value)) {
          values[key] = value;
        }
      }
      return values;
    };

    Entity.prototype.$links = function() {
      var key, links, value;
      links = {};
      for (key in this) {
        if (!hasProp.call(this, key)) continue;
        value = this[key];
        if (isEntity(value)) {
          links[key] = value;
        }
      }
      return links;
    };

    Entity.prototype.$linksArray = function() {
      var key, results, value;
      results = [];
      for (key in this) {
        if (!hasProp.call(this, key)) continue;
        value = this[key];
        if (isEntity(value)) {
          results.push(value);
        }
      }
      return results;
    };

    Entity.prototype.$isFetched = function(eagerness, visited) {
      var fetched, key, ref, subEntity;
      if (eagerness == null) {
        eagerness = 1;
      }
      if (visited == null) {
        visited = {};
      }
      if ((visited[this.$id()] != null) && eagerness > -1 && visited[this.$id()] >= eagerness) {
        return true;
      }
      if (eagerness === 0) {
        return true;
      }
      if (eagerness === 1 && this.$.fetched) {
        return true;
      }
      if (!this.$.fetched) {
        return false;
      }
      visited[this.$id()] = eagerness;
      fetched = true;
      ref = this.$links();
      for (key in ref) {
        subEntity = ref[key];
        if (eagerness === -1) {
          if (visited[subEntity.$id()] == null) {
            fetched = fetched && subEntity.$isFetched(eagerness, visited);
          }
        } else {
          fetched = fetched && subEntity.$isFetched(eagerness - 1, visited);
        }
      }
      return fetched;
    };

    Entity.prototype.$fetch = function(opts) {
      return this.$.weaver.get(this.$.id, opts);
    };

    Entity.prototype.$push = function(attribute, value) {
      var payload;
      if (isEntity(attribute)) {
        if (this[attribute.$id()] == null) {
          this[attribute.$id()] = attribute;
        }
        if (this.$.weaver.channel != null) {
          payload = {
            source: {
              id: this.$id(),
              type: this.$type()
            },
            key: attribute.$id(),
            target: {
              id: attribute.$id(),
              type: attribute.$type()
            }
          };
          return this.$.weaver.channel.link(payload);
        }
      } else {
        if (value != null) {
          if (this[attribute] !== value) {
            this[attribute] = value;
          }
        } else {
          value = this[attribute];
        }
        if (this.$.weaver.channel != null) {
          if (isEntity(value)) {
            payload = {
              source: {
                id: this.$id(),
                type: this.$type()
              },
              key: attribute,
              target: {
                id: value.$id(),
                type: value.$type()
              }
            };
            return this.$.weaver.channel.link(payload);
          } else {
            payload = {
              source: {
                id: this.$id(),
                type: this.$type()
              },
              key: attribute,
              target: {
                value: value,
                datatype: ''
              }
            };
            return this.$.weaver.channel.update(payload);
          }
        }
      }
    };

    Entity.prototype.$remove = function(key) {
      var value;
      if (isEntity(key)) {
        delete this[key.$id()];
        if (this.$.weaver.channel != null) {
          return this.$.weaver.channel.unlink({
            id: this.$.id,
            key: key.$id()
          });
        }
      } else {
        value = this[key];
        delete this[key];
        if (this.$.weaver.channel != null) {
          if (isEntity(value)) {
            return this.$.weaver.channel.unlink({
              id: this.$.id,
              key: key
            });
          } else {
            return this.$.weaver.channel.remove({
              id: this.$.id,
              attribute: key
            });
          }
        }
      }
    };

    Entity.prototype.$destroy = function() {
      if (this.$.weaver.channel != null) {
        return this.$.weaver.channel.destroy({
          id: this.$.id
        });
      }
    };

    Entity.prototype.$on = function(key, callback) {
      if (this.$.listeners[key] == null) {
        this.$.listeners[key] = [];
      }
      return this.$.listeners[key].push(callback);
    };

    Entity.prototype.$fire = function(key) {
      var callback, i, len, ref, results;
      if (this.$.listeners[key] != null) {
        ref = this.$.listeners[key];
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          callback = ref[i];
          results.push(callback.call(key));
        }
        return results;
      }
    };

    Entity.prototype.$weaver = function(weaver) {
      this.$.weaver = weaver;
      return this;
    };

    Entity.prototype.$isEntity = function() {
      return true;
    };

    Entity.prototype.$withoutEntities = function() {
      var key, ref, val;
      ref = this.$links();
      for (key in ref) {
        val = ref[key];
        delete this[key];
      }
      return this;
    };

    return Entity;

  })();

}).call(this);

(function() {
  var Entity, Promise, Repository, cuid, io,
    hasProp = {}.hasOwnProperty;

  io = require('socket.io-client');

  cuid = require('cuid');

  Promise = require('bluebird');

  Entity = require('./entity');

  module.exports = Repository = (function() {
    function Repository(weaver) {
      this.weaver = weaver;
      this.entities = {};
      this.listeners = {};
    }

    Repository.prototype.contains = function(id) {
      return this.entities[id] != null;
    };

    Repository.prototype.get = function(id) {
      return this.entities[id];
    };

    Repository.prototype.add = function(entity) {
      this.entities[entity.$id()] = entity;
      return entity;
    };

    Repository.prototype.size = function() {
      var key;
      return ((function() {
        var ref, results;
        ref = this.entities;
        results = [];
        for (key in ref) {
          if (!hasProp.call(ref, key)) continue;
          results.push(key);
        }
        return results;
      }).call(this)).length;
    };

    Repository.prototype.isEmpty = function() {
      return this.size() === 0;
    };

    Repository.prototype.clear = function() {
      return this.entities = {};
    };

    Repository.prototype.store = function(entity) {
      var addConnections, added, connection, connections, i, len, processing, repoObject, repoSubject;
      connections = [];
      added = {};
      addConnections = function(parent) {
        var child, key, ref, results;
        added[parent.$id()] = true;
        ref = parent.$links();
        results = [];
        for (key in ref) {
          child = ref[key];
          connections.push({
            subject: parent,
            predicate: key,
            object: child
          });
          if (added[child.$id()] == null) {
            results.push(addConnections(child));
          } else {
            results.push(void 0);
          }
        }
        return results;
      };
      addConnections(entity);
      if (connections.length === 0) {
        if (!this.contains(entity.$id())) {
          this.track(this.add(entity));
        }
      } else {
        processing = {};
        for (i = 0, len = connections.length; i < len; i++) {
          connection = connections[i];
          if (!this.contains(connection.subject.$id())) {
            repoSubject = connection.subject.$withoutEntities();
            processing[repoSubject.$id()] = true;
            this.track(this.add(repoSubject));
          } else {
            repoSubject = this.get(connection.subject.$id());
            repoObject = this.get(connection.object.$id());
            if (repoSubject.$.fetched && (repoObject != null) && repoObject.$.fetched && !processing[repoSubject.$id()]) {
              continue;
            } else {
              processing[repoSubject.$id()] = true;
              if (connection.subject.$.fetched) {
                repoSubject.$.fetched = true;
              }
            }
          }
          if (!this.contains(connection.object.$id())) {
            repoObject = connection.object.$withoutEntities();
            this.track(this.add(repoObject));
            processing[repoObject.$id()] = true;
          } else {
            repoObject = this.get(connection.object.$id());
            processing[repoObject.$id()] = true;
            if (connection.object.$.fetched) {
              repoObject.$.fetched = true;
            }
          }
          repoSubject[connection.predicate] = repoObject;
        }
      }
      return this.get(entity.$id());
    };

    Repository.prototype.track = function(entity) {
      var self;
      this.weaver.channel.onUpdate(entity.$.id, function(payload) {
        if (payload.value != null) {
          entity[payload.attribute] = payload.value;
        } else {
          delete entity[payload.attribute];
        }
        return entity.$fire(payload.attribute);
      });
      self = this;
      this.weaver.channel.onLinked(entity.$.id, function(payload) {
        self.weaver.get(payload.target).then(function(newLink) {
          return entity[payload.key] = newLink;
        });
        return entity.$fire(payload.key);
      });
      this.weaver.channel.onUnlinked(entity.$.id, function(payload) {
        delete entity[payload.key];
        return entity.$fire(payload.key);
      });
      return entity;
    };

    return Repository;

  })();

}).call(this);

(function() {
  var Promise, Socket, io;

  io = require('socket.io-client');

  Promise = require('bluebird');

  module.exports = Socket = (function() {
    function Socket(address) {
      this.address = address;
      this.io = io.connect(this.address, {
        reconnection: true
      });
    }

    Socket.prototype.read = function(payload) {
      return this.emit('read', payload);
    };

    Socket.prototype.create = function(payload) {
      return this.emit('create', payload);
    };

    Socket.prototype.bulkNodes = function(payload) {
      return this.emit('bulkNodes', payload);
    };

    Socket.prototype.bulkRelations = function(payload) {
      return this.emit('bulkRelations', payload);
    };

    Socket.prototype.endBulk = function() {
      return this.emit('bulkEnd');
    };

    Socket.prototype.startBulk = function() {
      return this.emit('bulkStart');
    };

    Socket.prototype.createDict = function(payload) {
      return this.emit('createDict', payload);
    };

    Socket.prototype.readDict = function(id) {
      return this.emit('readDict', id);
    };

    Socket.prototype.authenticate = function(payload) {
      return this.emit('authenticate', payload);
    };

    Socket.prototype.update = function(payload) {
      return this.emit('update', payload);
    };

    Socket.prototype.link = function(payload) {
      return this.emit('link', payload);
    };

    Socket.prototype.unlink = function(payload) {
      return this.emit('unlink', payload);
    };

    Socket.prototype.destroy = function(payload) {
      return this.emit('destroy', payload);
    };

    Socket.prototype.remove = function(payload) {
      return this.emit('remove', payload);
    };

    Socket.prototype.wipe = function() {
      return this.emit('wipe', {});
    };

    Socket.prototype.wipeWeaver = function() {
      return this.emit('wipeWeaver', {});
    };

    Socket.prototype.bootstrapFromUrl = function(url) {
      return this.emit('bootstrapFromUrl', url);
    };

    Socket.prototype.bootstrapFromJson = function(json) {
      return this.emit('bootstrapFromJson', json);
    };

    Socket.prototype.onUpdate = function(id, callback) {
      return this.on(id + ':updated', callback);
    };

    Socket.prototype.onLinked = function(id, callback) {
      return this.on(id + ':linked', callback);
    };

    Socket.prototype.onUnlinked = function(id, callback) {
      return this.on(id + ':unlinked', callback);
    };

    Socket.prototype.emit = function(key, body) {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          return _this.io.emit(key, body, function(response) {
            if (response === 0) {
              return resolve();
            } else {
              return resolve(response);
            }
          });
        };
      })(this));
    };

    Socket.prototype.on = function(event, callback) {
      return this.io.on(event, callback);
    };

    Socket.prototype.disconnect = function() {
      return this.io.disconnect();
    };

    Socket.prototype.queryFromView = function(payload) {
      return this.emit('queryFromView', payload);
    };

    Socket.prototype.queryFromFilters = function(payload) {
      return this.emit('queryFromFilters', payload);
    };

    Socket.prototype.nativeQuery = function(payload) {
      return this.emit('nativeQuery', payload);
    };

    return Socket;

  })();

}).call(this);

(function() {
  var Entity, Promise, Repository, Socket, Weaver, WeaverCommons, WeaverEntity, io, pjson;

  io = require('socket.io-client');

  Promise = require('bluebird');

  Socket = require('./socket');

  Entity = require('./entity');

  WeaverEntity = require('./weaverEntity');

  Repository = require('./repository');

  WeaverCommons = require('weaver-commons-js');

  pjson = require('../package.json');

  module.exports = Weaver = (function() {
    Weaver.Entity = Entity;

    Weaver.Socket = Socket;

    Weaver.Repository = Repository;

    function Weaver() {
      console.log('WeaverSDK: ' + pjson.version);
      this.repository = new Repository(this);
    }

    Weaver.prototype.connect = function(address) {
      this.channel = new Socket(address);
      return this;
    };

    Weaver.prototype.disconnect = function() {
      this.channel.disconnect();
      return this;
    };

    Weaver.prototype.authenticate = function(token) {
      return this.channel.authenticate(token);
    };

    Weaver.prototype.database = function(database) {
      this.channel = database;
      return this;
    };


    /*
     Tells the server that the bulk insertion has finished
     Used after startBulk
     */

    Weaver.prototype.endBulk = function() {
      return this.channel.endBulk();
    };


    /*
     Tells the server that the bulk insertion starts
     Used before endBulk
     */

    Weaver.prototype.startBulk = function() {
      return this.channel.startBulk();
    };


    /*
     Will inserts a entity into db
     The old weaver.add converted to the new way
     */

    Weaver.prototype.node = function(object, id) {
      var weaverEntity;
      weaverEntity = new WeaverEntity(object, id);
      return this.channel.create(weaverEntity).then(function(object) {
        if (object === 200) {
          return weaverEntity;
        } else {
          return 'error';
        }
      });
    };


    /*
     Will update the attributes of an entity
     */

    Weaver.prototype.update = function(object, id) {
      var weaverEntity;
      weaverEntity = new WeaverEntity(object, id);
      return this.channel.update(weaverEntity).then((function(_this) {
        return function(res, err) {
          if (res[0] === 200) {
            return weaverEntity;
          } else {
            return 'error';
          }
        };
      })(this));
    };


    /*
     Stores data in object format into the Redis db
     */

    Weaver.prototype.dict = function(object, id) {
      var weaverEntity;
      weaverEntity = new WeaverEntity(object, id);
      return this.channel.createDict(weaverEntity);
    };


    /*
     Retireves data from the Redis db
     */

    Weaver.prototype.getDict = function(id) {
      var error, error1;
      try {
        return this.channel.readDict({
          id: id
        }).bind(this).then((function(_this) {
          return function(res, err) {
            if (err) {
              err;
            }
            if (res) {
              return res;
            }
          };
        })(this));
      } catch (error1) {
        error = error1;
        return error;
      }
    };


    /*
     Retireves an entity
     */

    Weaver.prototype.getNode = function(id, opts) {
      if (opts == null) {
        opts = {};
      }
      if (opts.eagerness == null) {
        opts.eagerness = 1;
      }
      if (typeof id === 'string') {
        id = id;
      }
      if (typeof id === 'object') {
        id = id.id;
      }
      return this.channel.read({
        id: id,
        opts: opts
      }).bind(this).then(function(object) {
        var entity, error, error1;
        try {
          entity = JSON.parse(object);
          if (!entity.id && entity.attributes.length === 0 && entity.relations.length === 0) {
            return 'The entity does not exits';
          } else {
            return entity;
          }
        } catch (error1) {
          error = error1;
          return 'Error reading ' + id;
        }
      });
    };


    /*
     Makes a relationship between tow entities
     If any of those does not extits will be created
     */

    Weaver.prototype.link = function(source, relationTarget) {
      var entity;
      entity = new WeaverEntity().relate(source, relationTarget);
      return this.channel.link(entity).then(function(object) {
        if (object === 200) {
          return entity;
        } else {
          return 'error linking ' + source;
        }
      });
    };


    /*
     Deletes relationships
     */

    Weaver.prototype.unlink = function(source, relationTarget) {
      var entity;
      entity = new WeaverEntity().relate(source, relationTarget);
      return this.channel.unlink(entity).then(function(object) {
        if (object[0] === '200') {
          return object[0];
        } else {
          return 'error unlinking ' + source;
        }
      });
    };

    Weaver.prototype.bulkNodes = function(bulkPayload) {
      return this.channel.bulkNodes(bulkNodes).then(function(object) {
        if (object[0] === '200') {
          return object[0];
        } else {
          return 'error destroying entity';
        }
      });
    };

    Weaver.prototype.bulkRelations = function(bulkPayload) {
      return this.channel.bulkRelations(bulkNodes).then(function(object) {
        if (object[0] === '200') {
          return object[0];
        } else {
          return 'error destroying entity';
        }
      });
    };


    /*
     Wipes the DB
     */

    Weaver.prototype.wipe = function() {
      return this.channel.wipe().then(function(object) {
        if (object[0] === '200') {
          return object[0];
        } else {
          return 'error wipping db';
        }
      });
    };


    /*
     Wipes the weaver DB, (in case of neo4j will removes all the nodes with label:INDIVIDUAL and $ID value property)
     */

    Weaver.prototype.wipeWeaver = function() {
      return this.channel.wipeWeaver().then(function(object) {
        if (object[0] === '200') {
          return object[0];
        } else {
          return 'error wipping weaver db';
        }
      });
    };


    /*
     Deletes an entity (a node)
     */

    Weaver.prototype.destroy = function(individual) {
      var entity;
      entity = new WeaverEntity({}, individual);
      return this.channel.destroy(entity).then(function(object) {
        if (object[0] === '200') {
          return object[0];
        } else {
          return 'error destroying entity';
        }
      });
    };

    return Weaver;

  })();

  if (typeof window !== "undefined" && window !== null) {
    window.Weaver = Weaver;
  }

}).call(this);

(function() {
  var WeaverEntity, cuid;

  cuid = require('cuid');

  module.exports = WeaverEntity = (function() {
    var typeIsArray;

    typeIsArray = Array.isArray || function(value) {
      return {}.toString.call(value) === '[object Array]';
    };

    function WeaverEntity(object, id) {
      var attribute, attributes, key, value;
      attributes = [];
      if (typeof object === 'string' && !id) {
        this.id = object;
      } else {
        for (key in object) {
          value = object[key];
          attribute = {};
          if (key === 'id') {
            attributes[attributes.length - 1].id = value;
          } else {
            attribute.key = key;
            attribute.value = value;
            attributes.push(attribute);
          }
        }
        if (id) {
          if (typeof id === 'object') {
            this.id = id.id;
          } else {
            this.id = id;
          }
        } else {
          this.id = cuid();
        }
      }
      if (attributes.length !== 0) {
        this.attributes = attributes;
      }
    }

    WeaverEntity.prototype.relate = function(source, relationTarget) {
      var i, index, j, key, len, len1, ref, rel, relation, relations, tar, value;
      relations = [];
      for (key in relationTarget) {
        value = relationTarget[key];
        relation = {};
        relation.relation = key;
        if (typeof value === 'string') {
          relation.target = value;
        }
        if (typeof value === 'object') {
          relation.target = value.id;
        }
        if (typeIsArray(value)) {
          relation.target = value;
        }
        relations.push(relation);
      }
      for (index = i = 0, len = relations.length; i < len; index = ++i) {
        relation = relations[index];
        if (typeIsArray(relation.target)) {
          delete relations[index];
          ref = relation.target;
          for (j = 0, len1 = ref.length; j < len1; j++) {
            tar = ref[j];
            rel = {};
            rel.relation = relation.relation;
            rel.target = tar;
            relations.push(rel);
          }
        }
      }
      if (typeof source === 'string') {
        this.id = source;
      } else {
        this.id = source.id;
      }
      if (relations.length !== 0) {
        this.relations = relations;
      }
      return this;
    };

    return WeaverEntity;

  })();

}).call(this);
