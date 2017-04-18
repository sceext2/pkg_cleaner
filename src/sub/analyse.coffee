# analyse.coffee, pkg_cleaner/src/sub/

_async = require '../_async'
util = require '../util'
config = require '../config'

parse_rule = require '../a/parse_rule'


analyse = ->
  console.log "pkgc.D: load pkg db `#{config.pkg_db_file}` "
  pkg_db = JSON.parse (await _async.read_file config.pkg_db_file)

  console.log "pkgc.D: load rule from `#{config.rule_list}` "
  rule_raw = JSON.parse (await _async.read_file config.rule_list)

  rule = parse_rule rule_raw
  console.log "pkgc: level: #{rule.level_index.join(' ')} "
  # FIXME print rule count
  for i in rule.level_index
    l = rule.level[i]
    console.log "pkgc.D: level #{i}/white: #{Object.keys(l.white).length} rules "
    console.log "pkgc.D: level #{i}/black: #{Object.keys(l.black).length} rules "

  # TODO


module.exports = analyse  # async
