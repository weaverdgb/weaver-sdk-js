
_       = require('lodash')
Weaver  = require('./Weaver')

executeWpath = (node, hops, res = [], trail = {}) ->

  newRow = (blueprint) ->
    row = {}
    row[b] = n for b, n of blueprint
    row

  [hop, hops...] = hops
  if !hop?
    res.push(trail) if _.keys(trail).length > 0
    return
  [key, binding] = hop.split('?')

  # Optionally get the [] filter
  [key, filter] = key.split('[')
  [filter, ...] = filter.split(']') if filter?

  if node not instanceof Weaver.ModelClass or node.constructor.isAllowedRelation(key)
    for to in node.relation(key).all()
      if filterWpath(to, filter)
        row = newRow(trail)
        row[binding] = to if binding?
        executeWpath(to, hops, res, row)
          
filterWpath = (to, expr) ->
  return true if !expr?

  hasOrs = expr.indexOf('|') > -1
  hasAnds = expr.indexOf('&') > -1

  throw new Error("Wpath does not support combination of AND and OR") if hasOrs && hasAnds

  value = !hasOrs

  conditions = [expr]
  conditions = expr.split('|') if hasOrs
  conditions = expr.split('&') if hasAnds

  for condition in conditions
    met = undefined
    [action, key] = condition.split('=')
    switch action.trim()
      when 'id' 
        met = to.id() is key
      when 'class' 
        met = false
        if to.model?
          met |= def.id() is key for def in  to.relation(to.model.getMemberKey()).all()
      else throw new Error("Key #{action} not supported in wpath")
    if hasOrs
      value |= met
    else 
      value &= met

  value

module.exports =

  wpath: (node, expr = '', func, load = false) ->
    hops = expr.split('/')
    hops.splice(0,1) if hops[0] is ''
    res = []
    executeWpath(node, hops, res)
    func(row) for row in res if func?
    res
