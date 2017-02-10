Weaver = require('./Weaver')
util   = require('./util')

# Converts a string into a regex that matches it.
# Surrounding with \Q .. \E does this, we just need to escape any \E's in
# the text separately.
quote = (s) ->
  '\\Q' + s.replace('\\E', '\\E\\\\E\\Q') + '\\E';


class WeaverQuery

    constructor: (@target) ->
      @_restrict   = []
      @_equals     = {}
      @_orQueries  = []
      @_conditions = {}
      @_include    = []
      @_select     = []
      @_count       = false
      @_hollow      = false
      @_limit       = 100
      @_skip        = 0
      @_order       = []
      @_ascending   = true

    find: ->
      coreManager = Weaver.getCoreManager()
      coreManager.query(@).then((nodes) ->
        (new Weaver.Node()._loadFromQuery(node) for node in nodes)
      )

    count: ->
      @_count = true
      coreManager = Weaver.getCoreManager()
      coreManager.query(@)

    first: ->
      @_limit = 1
      @find().then((res) ->
        if res.length is 0
          Promise.reject({code:101, "Node not found"})
        else
          res[0]
      )

    get: (node) ->
      @restrict(node)
      @first()

    restrict: (nodes) ->
      addRestrict = (node) =>
        if util.isString(node)
          @_restrict.push(node)
        else if node instanceof Weaver.Node
          @_restrict.push(node.id())

      if util.isArray(nodes)
        @_restrict = [] # Clear
        addRestrict(node) for node in nodes
      else
        addRestrict(nodes)

      @

    equalTo: (key, value) ->
      delete @_conditions[key]
      @_equals[key] = value
      @

    _addCondition: (key, condition, value) ->
      delete @_equals[key]
      @_conditions[key] = @_conditions[key] or {}
      @_conditions[key][condition] = value
      @

    notEqualTo: (key, value) ->
      @_addCondition(key, '$ne', value);

    lessThan: (key, value) ->
      @_addCondition(key, '$lt', value);

    greaterThan: (key, value) ->
      @_addCondition(key, '$gt', value);

    lessThanOrEqualTo: (key, value) ->
      @_addCondition(key, '$lte', value);

    greaterThanOrEqualTo: (key, value) ->
      @_addCondition(key, '$gte', value);

    containedIn: (key, values) ->
      @_addCondition(key, '$in', values);

    notContainedIn: (key, values) ->
      @_addCondition(key, '$nin', values);

    containsAll: (key, values) ->
      @_addCondition(key, '$all', values);

    exists: (key) ->
      @_addCondition(key, '$exists', true);

    doesNotExist: (key) ->
      @_addCondition(key, '$exists', false);

    matches: (key, value) ->
      @_addCondition(key, '$regex', value);

    contains: (key, value) ->
      @_addCondition(key, '$regex', quote(value));

    startsWith: (key, value) ->
      @_addCondition(key, '$regex', '^' + quote(value));

    endsWith: (key, value) ->
      @_addCondition(key, '$regex', quote(value) + '$');

    matchesQuery: (key, weaverQuery) ->
      @_addCondition(key, '$inQuery', weaverQuery);

    doesNotMatchQuery: (key, query) ->
      @_addCondition(key, '$notInQuery', query);

    matchesKeyQuery: (key, queryKey, query) ->
      @_addCondition(key, '$select', {queryKey, query});

    doesNotMatchKeyInQuery: (key, queryKey, query) ->
      @_addCondition(key, '$dontSelect', {queryKey, query});

    order: (keys, ascending) ->
      @_order     = keys
      @_ascending = ascending
      @

    ascending: (keys) ->
      @order(keys, true)

    descending: (keys) ->
      @order(keys, false)

    skip: (skip) ->
      if typeof skip isnt 'number' or skip < 0
        throw new Error('You can only skip by a positive number')

      @_skip = skip
      @

    limit: (limit) ->
      if typeof limit isnt 'number' or limit < 0
        throw new Error('You can only set the limit to a positive number')

      @_limit = limit
      @

    include: (keys) ->
      @_include = keys
      @

    select: (keys) ->
      @_select = keys
      @

    hollow: (value) ->
      @_hollow = value
      @

    or: (queries) ->
      @_orQueries = queries
      @

    @or: (queries) ->
      query = new Weaver.Query()
      query.or(queries)
      query

    # Create, Update, Enter, Leave, Delete
    subscribe: ->
      coreManager = Weaver.getCoreManager()
      coreManager.subscribe(@)

    nativeQuery: (query)->
      coreManager = Weaver.getCoreManager()
      coreManager.nativeQuery(query, Weaver.currentProject())

# Export
module.exports = WeaverQuery
