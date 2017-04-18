# analyse.coffee, pkg_cleaner/src/sub/

_async = require '../_async'
util = require '../util'
config = require '../config'

parse_rule = require '../a/parse_rule'
resolve = require '../a/resolve'


analyse = ->
  console.log "pkgc.D: load pkg db `#{config.pkg_db_file}` "
  pkg_db = JSON.parse (await _async.read_file config.pkg_db_file)

  console.log "pkgc.D: load rule from `#{config.rule_list}` "
  rule_raw = JSON.parse (await _async.read_file config.rule_list)

  rule = parse_rule rule_raw
  # sort level
  level = rule.level_index.sort (a, b) ->
    a - b
  console.log "pkgc: level: #{level.join(' ')} "
  # process each level
  # TODO support multi-level
  for i in level
    l = rule.level[i]
    white = Object.keys l.white
    if white.length > 0
      console.log "pkgc.D: level #{i}/white: #{white.length} rules "
    # resolve each root (in white rules)
    tmp = {}
    for j in white
      console.log "pkgc.D: resolve root `#{j}` "
      tmp[j] = resolve.resolve_one_root pkg_db, j
    console.log "pkgc.D: merge result .. . "
    [pkg_db, pkg_list] = resolve.merge_result pkg_db, tmp
    console.log "pkgc.D: #{pkg_list.length} pkgs after merge "

    black = Object.keys l.black
    console.log "pkgc.D: level #{i}/black: #{black.length} rules "
    black_root = {}
    pkg_db.black_in_group = {}
    for j in black
      # TODO support black group
      if ! pkg_db.pkg_info[j]?
        console.log "pkgc.W: unknow pkg `#{j}` "
        continue
      p = pkg_db.pkg_info[j]
      if p.is_root
        console.log "pkgc.W: root `#{j}` is also in black list "
        black_root[j] = true
      if p.required_by_root?
        for k in p.required_by_root
          # check root is group
          if pkg_db.group_info[k]?
            pkg_db.black_in_group[j] = true
            console.log "pkgc.W: remove pkg `#{j}` in group `#{k}` "
          else
            black_root[k] = true
            console.log "pkgc.W: black pkg `#{j}` remove root `#{k}` "
    console.log "pkgc.D: black remove #{Object.keys(black_root).length} roots, #{Object.keys(pkg_db.black_in_group).length} black pkg in group "
  # TODO support multi-level
  # resolve again after black root
  console.log "pkgc.D: resolve again after black roots .. . "
  tmp = {}
  for j in white
    t = resolve.resolve_one_root pkg_db, j
    for k in t
      tmp[k] = true
  result = Object.keys(tmp)
  console.log "pkgc: #{result.length} pkgs to keep "

  # TODO support multi-level
  # check root required by root
  for i in white
    # TODO FIXME check group
    if ! pkg_db.pkg_info[i]?
      continue
    p = pkg_db.pkg_info[i]
    if p.required_by_root?
      for j in p.required_by_root
        if j != i
          console.log "pkgc.W: root `#{i}` is required by root `#{j}` "

  # make final result
  installed_pkg_list = pkg_db.pkg_list_installed
  user_roots = pkg_db.user_roots
  to_keep_pkg_list = tmp  # result

  # TODO check group and user_pkg list
  pkg_to_remove = {}
  for i in installed_pkg_list
    if ! to_keep_pkg_list[i]
      pkg_to_remove[i] = true
  user_roots_to_remove = {}
  for i in user_roots
    if ! to_keep_pkg_list[i]
      user_roots_to_remove[i] = true

  pkg_to_install = {}
  for i of to_keep_pkg_list
    if installed_pkg_list.indexOf(i) == -1
      pkg_to_install = true

  _print_pkg_list = (db, list) ->
    for i of list
      if ! db.pkg_info[i]?
        console.log "pkgc.D: unknow pkg `#{i}` "
      else
        p = db.pkg_info[i]
        console.log "#{p.repo}/#{p.name}"
        console.log "    #{p.desc}"
  # print result
  console.log "\npkgc: result: "
  console.log "    #{installed_pkg_list.length} pkgs current installed"
  console.log "    #{Object.keys(to_keep_pkg_list).length} pkgs to keep"
  console.log "    #{Object.keys(user_roots_to_remove).length} user roots to remove"
  console.log "    #{Object.keys(pkg_to_remove).length} pkgs to remove"
  console.log "    #{Object.keys(pkg_to_install).length} pkgs to install"

  console.log "\npkgs (user roots) to REMOVE"
  _print_pkg_list pkg_db, user_roots_to_remove
  console.log "\npkgs to INSTALL"
  _print_pkg_list pkg_db, pkg_to_install

  # TODO


module.exports = analyse  # async
