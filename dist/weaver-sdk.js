(function() {
  var Entity, cuid, isEntity, isObject, isReference,
    __hasProp = {}.hasOwnProperty;

  cuid = require('cuid');

  isObject = function(object) {
    return Object.prototype.toString.call(object) === '[object Object]';
  };

  isReference = function(object) {
    return object['_REF'] != null;
  };

  isEntity = function(value) {
    return typeof value.isEntity === 'function' && value.isEntity();
  };

  module.exports = Entity = (function() {
    Entity.create = function(object) {
      var data, fetched, id, key, type, value;
      type = object['_META'].type;
      fetched = object['_META'].fetched;
      id = object['_META'].id;
      data = {};
      for (key in object) {
        if (!__hasProp.call(object, key)) continue;
        value = object[key];
        if (key !== '_META') {
          data[key] = value;
        }
      }
      return new Entity(data, type, fetched, id);
    };

    Entity.build = function(object, weaver) {
      var entity, id, key, references, register, value;
      references = {};
      register = function(value) {
        var entity, key, _results;
        entity = Entity.create(value).weaver(weaver);
        references[entity.id()] = entity;
        _results = [];
        for (key in entity) {
          value = entity[key];
          if (key !== '$') {
            if (isObject(value) && (value['_REF'] == null)) {
              _results.push(register(value));
            } else {
              _results.push(void 0);
            }
          }
        }
        return _results;
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
        type = '_ROOT';
      }
      if (fetched == null) {
        fetched = true;
      }
      this.$ = {
        id: id,
        type: type,
        fetched: fetched
      };
      for (key in data) {
        value = data[key];
        this[key] = value;
      }
    }

    Entity.prototype.id = function() {
      return this.$.id;
    };

    Entity.prototype.type = function() {
      return this.$.type;
    };

    Entity.prototype.values = function() {
      var key, value, values;
      values = {};
      for (key in this) {
        if (!__hasProp.call(this, key)) continue;
        value = this[key];
        if (key !== '$' && key !== isEntity(value)) {
          values[key] = value;
        }
      }
      return values;
    };

    Entity.prototype.links = function() {
      var key, links, value;
      links = {};
      for (key in this) {
        if (!__hasProp.call(this, key)) continue;
        value = this[key];
        if (isEntity(value)) {
          links[key] = value;
        }
      }
      return links;
    };

    Entity.prototype.isFetched = function(eagerness, visited) {
      var fetched, key, subEntity, _ref;
      if (eagerness == null) {
        eagerness = 1;
      }
      if (visited == null) {
        visited = {};
      }
      if ((visited[this.id()] != null) && eagerness > -1 && visited[this.id()] >= eagerness) {
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
      fetched = true;
      _ref = this.links();
      for (key in _ref) {
        subEntity = _ref[key];
        if (eagerness === -1) {
          if (visited[subEntity.id()] == null) {
            fetched = fetched && subEntity.isFetched(eagerness - 1, visited);
          }
        } else {
          fetched = fetched && subEntity.isFetched(eagerness - 1, visited);
        }
      }
      if (fetched) {
        visited[this.id()] = eagerness;
      }
      return fetched;
    };

    Entity.prototype.fetch = function(opts) {
      return this.$.weaver.get(this.$.id, opts);
    };

    Entity.prototype.push = function(attribute, value) {
      if (isEntity(attribute)) {
        if (this[attribute.id()] == null) {
          this[attribute.id()] = attribute;
        }
        return this.$.weaver.socket.emit('link', {
          id: this.$.id,
          key: attribute.id(),
          target: attribute.id()
        });
      } else {
        if ((this[attribute] == null) && (value != null)) {
          this[attribute] = value;
        }
        if (value == null) {
          value = this[attribute];
        }
        if (isEntity(value)) {
          return this.$.weaver.socket.emit('link', {
            id: this.$.id,
            key: attribute,
            target: value.id()
          });
        } else {
          return this.$.weaver.socket.emit('update', {
            id: this.$.id,
            attribute: attribute,
            value: this[attribute]
          });
        }
      }
    };

    Entity.prototype.remove = function(key) {
      var value;
      if (isEntity(key)) {
        delete this[key.id()];
        return this.$.weaver.socket.emit('unlink', {
          id: this.$.id,
          key: key.id()
        });
      } else {
        value = this[key];
        delete this[key];
        if (isEntity(value)) {
          return this.$.weaver.socket.emit('unlink', {
            id: this.$.id,
            key: key
          });
        } else {
          return this.$.weaver.socket.emit('update', {
            id: this.$.id,
            attribute: key,
            value: null
          });
        }
      }
    };

    Entity.prototype.destroy = function() {
      return this.$.weaver.socket.emit('delete', {
        id: this.$.id
      });
    };

    Entity.prototype.weaver = function(weaver) {
      this.$.weaver = weaver;
      return this;
    };

    Entity.prototype.isEntity = function() {
      return true;
    };

    Entity.prototype.withoutEntities = function() {
      var key, val, _ref;
      _ref = this.links();
      for (key in _ref) {
        val = _ref[key];
        delete this[key];
      }
      return this;
    };

    return Entity;

  })();

}).call(this);

(function() {
  var Entity, Promise, Repository, cuid, io,
    __hasProp = {}.hasOwnProperty;

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
      this.entities[entity.id()] = entity;
      return entity;
    };

    Repository.prototype.size = function() {
      var key;
      return ((function() {
        var _ref, _results;
        _ref = this.entities;
        _results = [];
        for (key in _ref) {
          if (!__hasProp.call(_ref, key)) continue;
          _results.push(key);
        }
        return _results;
      }).call(this)).length;
    };

    Repository.prototype.isEmpty = function() {
      return this.size() === 0;
    };

    Repository.prototype.clear = function() {
      return this.entities = {};
    };

    Repository.prototype.store = function(entity) {
      var addConnections, added, connection, connections, processing, repoObject, repoSubject, _i, _len;
      connections = [];
      added = {};
      addConnections = function(parent) {
        var child, key, _ref, _results;
        added[parent.id()] = true;
        _ref = parent.links();
        _results = [];
        for (key in _ref) {
          child = _ref[key];
          connections.push({
            subject: parent,
            predicate: key,
            object: child
          });
          if (added[child.id()] == null) {
            _results.push(addConnections(child));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };
      addConnections(entity);
      if (connections.length === 0) {
        if (!this.contains(entity.id())) {
          this.track(this.add(entity));
        }
      } else {
        processing = {};
        for (_i = 0, _len = connections.length; _i < _len; _i++) {
          connection = connections[_i];
          if (!this.contains(connection.subject.id())) {
            repoSubject = connection.subject.withoutEntities();
            processing[repoSubject.id()] = true;
            this.track(this.add(repoSubject));
          } else {
            repoSubject = this.get(connection.subject.id());
            repoObject = this.get(connection.object.id());
            if (repoSubject.$.fetched && (repoObject != null) && repoObject.$.fetched && !processing[repoSubject.id()]) {
              continue;
            } else {
              processing[repoSubject.id()] = true;
              if (connection.subject.$.fetched) {
                repoSubject.$.fetched = true;
              }
            }
          }
          if (!this.contains(connection.object.id())) {
            repoObject = connection.object.withoutEntities();
            this.track(this.add(repoObject));
            processing[repoObject.id()] = true;
          } else {
            repoObject = this.get(connection.object.id());
            processing[repoObject.id()] = true;
            if (connection.object.$.fetched) {
              repoObject.$.fetched = true;
            }
          }
          repoSubject[connection.predicate] = repoObject;
        }
      }
      return this.get(entity.id());
    };

    Repository.prototype.track = function(entity) {
      var self;
      this.weaver.socket.on(entity.$.id + ':updated', function(payload) {
        if (payload.value != null) {
          return entity[payload.attribute] = payload.value;
        } else {
          return delete entity[payload.attribute];
        }
      });
      self = this;
      this.weaver.socket.on(entity.$.id + ':linked', function(payload) {
        return self.weaver.get(payload.target).then(function(newLink) {
          return entity[payload.key] = newLink;
        });
      });
      this.weaver.socket.on(entity.$.id + ':unlinked', function(payload) {
        return delete entity[payload.key];
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

    Socket.prototype.read = function(id, opts) {
      return this.emit('read', {
        id: id,
        opts: opts
      });
    };

    Socket.prototype.create = function(type, id, data) {
      return this.emit('create', {
        type: type,
        id: id,
        data: data
      });
    };

    Socket.prototype.emit = function(key, body) {
      var deferred;
      deferred = Promise.defer();
      this.io.emit(key, body, function(response) {
        if (response === 0) {
          return deferred.resolve();
        } else {
          return deferred.resolve(response);
        }
      });
      return deferred.promise;
    };

    Socket.prototype.on = function(event, callback) {
      return this.io.on(event, callback);
    };

    return Socket;

  })();

}).call(this);

(function() {
  var Entity, Promise, Repository, Socket, Weaver, cuid, io;

  io = require('socket.io-client');

  cuid = require('cuid');

  Promise = require('bluebird');

  Socket = require('./socket');

  Entity = require('./entity');

  Repository = require('./repository');

  module.exports = Weaver = (function() {
    function Weaver(address) {
      this.address = address;
      this.socket = new Socket(this.address);
      this.repository = new Repository(this);
    }

    Weaver.prototype.add = function(data, type, id) {
      var entity;
      entity = new Entity(data, type, true, id).weaver(this);
      this.socket.create(type, entity.id(), data);
      return this.repository.store(entity);
    };

    Weaver.prototype.get = function(id, opts) {
      if (opts == null) {
        opts = {};
      }
      if (opts.eagerness == null) {
        opts.eagerness = 1;
      }
      if (this.repository.contains(id) && this.repository.get(id).isFetched(opts.eagerness)) {
        return Promise.resolve(this.repository.get(id));
      } else {
        return this.socket.read(id, opts).bind(this).then(function(object) {
          var entity;
          entity = Entity.build(object, this);
          return this.repository.store(entity);
        });
      }
    };

    Weaver.prototype.print = function(id, opts) {
      return this.get(id, opts).then(function(entity) {
        return console.log(entity);
      });
    };

    Weaver.prototype.local = function(id) {
      return this.repository.get(id);
    };

    return Weaver;

  })();

  if (typeof window !== "undefined" && window !== null) {
    window.Weaver = Weaver;
  }

}).call(this);
