# resolve.coffee, pkg_cleaner/src/a/


resolve_one_root = (db, pkg_name) ->
  todo = [pkg_name]
  todo_new = []
  resolved = {}

  _resolve_one = (pkg_name) ->
    if resolved[pkg_name]
      return
    if db.user_pkg_list.indexOf(pkg_name) != -1
      console.log "pkgc.D: resolve: ignore user_pkg `#{pkg_name}` "
      return
    if db.bad_pkg.indexOf(pkg_name) != -1
      console.log "pkgc.W: resolve: skip BAD pkg `#{pkg_name}` "
      return
    # check is group
    if db.group_info[pkg_name]?
      console.log "pkgc.D: resolve: GROUP #{pkg_name} "
      todo_new = todo_new.concat db.group_info[pkg_name].pkg
    else if db.pkg_info[pkg_name]?
      if db.pkg_info[pkg_name].dep?
        todo_new = todo_new.concat db.pkg_info[pkg_name].dep
      resolved[pkg_name] = true
    # check provide
    else if db.provide[pkg_name]?
      todo_new.push db.provide[pkg_name]
    else
      console.log "pkgc.W: resolve: unknow pkg `#{pkg_name}` "
  # main resolve loop
  while todo.length > 0
    for i in todo
      # check black in group
      if db.black_in_group?
        if db.black_in_group[i]
          console.log "pkgc.D: resolve: skip black_in_group, `#{i}` "
          continue
      _resolve_one i
    todo = todo_new
    todo_new = []
  Object.keys resolved

merge_result = (db, result) ->
  o = {}
  pi = db.pkg_info
  for i of result
    # set is_root
    if pi[i]?
      pi[i].is_root = true
    # set required_by_root
    for j in result[i]
      o[j] = true
      if ! pi[j]?
        console.log "pkgc.E: unknow pkg `#{j}` "
        continue
      if ! pi[j].required_by_root?
        pi[j].required_by_root = []
      pi[j].required_by_root.push i
  [db, Object.keys(o)]


module.exports = {
  resolve_one_root
  merge_result
}
