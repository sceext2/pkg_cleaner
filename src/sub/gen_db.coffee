# gen_db.coffee, pkg_cleaner/src/sub/

config = require '../config'
util = require '../util'
# NOTE only support `pacman` now
_pm = require '../_pm/pacman'


_save_db_file = (o) ->
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
    bad_pkg: []
    bad_group: []
    # TODO
    provide: {}
    replace: {}

    pkg_info: {}
  }
  console.log "pkgc: get pkg list in each group .. . "
  gi = await _pm.get_group_info_list group_list
  pkg_list_2 = []
  for i of gi.group_info
    pkg_list_2 = pkg_list_2.concat gi.group_info[i].pkg
  o.bad_group = gi.bad_group

  console.log "pkgc: getting pkg info .. . "
  pi = await _pm.get_pkg_info_list pkg_list_1.concat(pkg_list_2)
  o.pkg_info = pi.pkg_info
  o.bad_pkg = pi.bad_pkg
  console.log "pkgc: resolving dependencies .. . "
  todo = pkg_list_1.concat pkg_list_2
  todo_new = []
  resolved = {}
  # resolve one pkg
  # FIXME TODO support `provide` and `replace`
  _resolve_one = (pkg_name) ->
    if resolved[pkg_name]
      return
    if o.bad_pkg.indexOf(pkg_name) != -1
      console.log "pkgc.W: resolve: skip BAD pkg `#{pkg_name}`"
      return
    if ! o.pkg_info[pkg_name]?
      o.pkg_info[pkg_name] = await _pm.get_pkg_info pkg_name
    console.log "pkgc.D: reslove pkg `#{pkg_name}`"
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
    # one resolved
    resolved[pkg_name] = true
  while todo.length > 0
    for i in todo
      try
        await _resolve_one i
      catch e
        o.bad_pkg.push i
        console.log "pkgc.W: resolve pkg `#{i}` FAILED"
    todo = todo_new
    todo_new = []
  # done
  console.log "pkgc.D: o.pkg_info length == #{Object.keys(o.pkg_info).length}, #{o.bad_pkg.length} bad pkgs"
  await _save_db_file o

module.exports = gen_db  # async
