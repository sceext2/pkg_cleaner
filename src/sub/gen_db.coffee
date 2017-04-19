# gen_db.coffee, pkg_cleaner/src/sub/

config = require '../config'
util = require '../util'
# NOTE only support `pacman` now
_pm = require '../_pm/pacman'


_save_db_file = (o) ->
  # bad_pkg_installed
  for i in o.pkg_list_installed
    if o.bad_pkg[i]
      o.bad_pkg_installed.push i
  # turn off installed bad_pkg
  for i in o.bad_pkg_installed
    o.bad_pkg[i] = false
  # turn off provide bad_pkg
  for i of o.provide
    o.bad_pkg[i] = false
  # restruct bad_pkg
  bp = o.bad_pkg
  o.bad_pkg = []
  for i of bp
    if bp[i]
      o.bad_pkg.push i

  console.log "pkgc.D: o.pkg_info length == #{Object.keys(o.pkg_info).length}, #{o.bad_pkg.length} bad pkgs"
  o.time = new Date().toISOString()
  text = util.print_json(o) + '\n'
  await util.write_file config.pkg_db_file, text
  console.log "pkgc: save db file #{config.pkg_db_file}"

gen_db = ->
  # get current installed pkg list
  pkg_list_1 = await _pm.get_installed_pkg_list()
  console.log "pkgc.I: #{pkg_list_1.length} pkgs installed"
  # get group list of installed pkgs
  group_list = await _pm.get_installed_group_list()
  console.log "pkgc.I: #{group_list.length} groups"

  o = {
    mark: config.PKGC_MARK
    version: config.PKGC_DB_VERSION
    pkgc_version: config.PKGC_VERSION

    pkg_list_installed: pkg_list_1
    group_list: group_list
    bad_pkg: {}
    bad_pkg_installed: []
    bad_group: []
    group_info: {}

    provide: {}
    replace: {}

    pkg_info: {}

    user_pkg_list: []
    user_roots: []
  }
  console.log "pkgc: get pkg list in each group .. . "
  gi = await _pm.get_group_info_list group_list
  pkg_list_2 = []
  for i of gi.group_info
    pkg_list_2 = pkg_list_2.concat gi.group_info[i].pkg
  o.bad_group = gi.bad_group
  Object.assign o.group_info, gi.group_info

  console.log "pkgc: getting pkg info .. . "
  pi = await _pm.get_pkg_info_list pkg_list_1.concat(pkg_list_2)
  Object.assign o.pkg_info, pi.pkg_info
  for i in pi.bad_pkg
    o.bad_pkg[i] = true
  console.log "pkgc: resolving dependencies .. . "
  todo = pkg_list_1.concat pkg_list_2
  todo_new = []
  resolved = {}

  _fetch_pkg_info = ->
    to = []
    for i in todo
      if (o.pkg_info[i]?) or o.bad_pkg[i]
        continue
      else
        to.push i
    if to.length > 0
      pi = await _pm.get_pkg_info_list to
      Object.assign o.pkg_info, pi.pkg_info
      for i in pi.bad_pkg
        o.bad_pkg[i] = true
  # resolve one pkg
  _resolve_one = (pkg_name) ->
    if resolved[pkg_name]
      return
    if o.bad_pkg[pkg_name]
      console.log "pkgc.W: resolve: skip BAD pkg `#{pkg_name}`"
      return
    #console.log "pkgc.D: reslove pkg `#{pkg_name}`"
    pi = o.pkg_info[pkg_name]
    # add dep and opt_dep
    if pi.dep?
      todo_new = todo_new.concat pi.dep
    if pi.opt_dep?
      # add opt_dep
      for i in pi.opt_dep
        if typeof i == 'object'
          todo_new.push i.name
        else
          todo_new.push i
    # check provide and replace
    if pi.provide?
      for i in pi.provide
        o.provide[i] = pkg_name
    if pi.replace?
      for i in pi.replace
        o.replace[i] = pkg_name
    # one resolved
    resolved[pkg_name] = true
  await _fetch_pkg_info()
  while todo.length > 0
    for i in todo
      try
        await _resolve_one i
      catch e
        o.bad_pkg[i] = true
        console.log "pkgc.W: resolve pkg `#{i}` FAILED"
        # FIXME
        console.log e.stack
    todo = todo_new
    await _fetch_pkg_info()
    todo_new = []

  o.user_pkg_list = await _pm.get_user_pkg_list()
  o.user_roots = await _pm.get_user_roots()
  # done
  await _save_db_file o

module.exports = gen_db  # async
