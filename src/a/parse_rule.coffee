# parse_rule.coffee, pkg_cleaner/src/a/


_RULE_VERSION = '0.1.0-1'

parse_rule = (raw) ->
  o = {
    level_index: []
    level: {}
  }

  _add_one_rule = (rule_type, rule_level, pkg_name) ->
    if ! o.level[rule_level]?
      o.level[rule_level] = {
        white: {}
        black: {}
      }
    r = o.level[rule_level][rule_type]
    if r[pkg_name]
      console.log "pkgc.W: dup root `#{pkg_name}` in rule "
    r[pkg_name] = true

  _parse_root = (r) ->
    if r.version != _RULE_VERSION
      console.log "pkgc.E: rule version mismatch: `#{r.version}` is not `#{_RULE_VERSION}` "
      throw new Error("rule version `#{r.version}` != `#{_RULE_VERSION}` ")

    for i in r.rule
      _parse_rule i
  _parse_rule = (r) ->
    if r.type?
      switch r.type
        when 'white', 'black'
          rule_type = r.type
        else
          console.log "pkgc.W: unknow rule type `#{r.type}` "
          rule_type = 'white'  # default rule_type
    else
      rule_type = 'white'
    if r.level?
      rule_level = r.level
    else
      rule_level = 0  # default rule_level
    for i in r.pkg
      _parse_pkg rule_type, rule_level, i
  _parse_pkg = (rule_type, rule_level, p) ->
    if typeof p == 'string'
      _add_one_rule rule_type, rule_level, p
    else
      if p.name?
        _add_one_rule rule_type, rule_level, p.name
      if p.rule?
        for i in p.rule
          _parse_rule i
  # start parse
  _parse_root(raw)
  o.level_index = Object.keys(o.level).map (x) ->
    JSON.parse x
  o

module.exports = parse_rule
