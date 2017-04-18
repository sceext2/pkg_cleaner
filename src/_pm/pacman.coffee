# pacman.coffee, pkg_cleaner/src/_pm/
# please run `# pacman -Syu` before start get info (get pkg_db)

_async = require '../_async'
util = require '../util'
config = require '../config'


# parse pacman output text

_parse_line = (raw) ->
  o = []
  for i in raw.split('\n')
    t = i.trim()
    if t != ''
      o.push t
  o

_p_pkg_list = (raw) ->
  o = []
  for i in _parse_line(raw)
    p = i.split(' ')[0].trim()
    o.push p
  o

_p_i_group_list = (raw) ->
  r = {}
  for i in _parse_line(raw)
    g = i.split(' ')[0].trim()
    r[g] = true
  o = []
  for i of r
    o.push i
  o

_p_group_info = (raw) ->
  o = []
  for i in _parse_line(raw)
    o.push i.split(' ')[1].trim()
  {
    pkg: o
  }

_p_group_info_list = (raw, group_list) ->
  o = {
    bad_group: []
    group_info: {}
  }
  for i in _parse_line(raw)
    [group_name, pkg_name] = i.split(' ')
    group_name = group_name.trim()
    pkg_name = pkg_name.trim()

    if ! o.group_info[group_name]?
      o.group_info[group_name] = {
        pkg: []
      }
    o.group_info[group_name].pkg.push pkg_name
  for i in group_list
    if ! o.group_info[i]?
      o.bad_group.push i
  o

_p_pkg_info_list = (raw, pkg_list) ->
  o = {
    bad_pkg: []
    pkg_info: {}
  }
  for i in raw.split('\n\n')
    pi = _p_pkg_info(i)
    o.pkg_info[pi.name] = pi
  for i in pkg_list
    if ! o.pkg_info[i]?
      o.bad_pkg.push i
  o

_p_pkg_info = (raw) ->
  # FIXME TODO support version deps
  _clean_dep_name = (raw) ->
    if raw.indexOf('>=') != -1
      raw[... raw.indexOf('>=')]
    else if raw.indexOf('=') != -1
      raw[... raw.indexOf('=')]
    else if raw.indexOf('>') != -1
      raw[... raw.indexOf('>')]
    else if raw.indexOf('<') != -1
      raw[... raw.indexOf('<')]
    else
      raw
  _parse_dep = (l) ->
    o = []
    for i in l
      o.push _clean_dep_name i
    o
  _parse_opt_dep = (i) ->
    if i.trim() == 'None'
      return
    i = i.trim()
    if i.indexOf(':') != -1
      p = i.split(':')
      key = _clean_dep_name p[0]
      value = p[1..].join(':').trim()
      o.opt_dep.push {
        name: key
        desc: value
      }
    else
      o.opt_dep.push i
  _split = (value) ->
    o = []
    for i in value.split(' ')
      t = i.trim()
      if t != ''
        o.push t
    o
  o = {}
  flag_opt_dep = false
  for i in raw.split('\n')
    if i.trim() == ''
      continue  # ignore empty line
    if flag_opt_dep
      if i.startsWith(' ')
        _parse_opt_dep i
      else
        flag_opt_dep = false
    else
      p = i.split(':')
      key = p[0].trim()
      value = p[1..].join(':').trim()

      switch key
        when 'Repository'
          o.repo = value
        when 'Name'
          o.name = value
        when 'Description'
          o.desc = value
        when 'Groups'
          if value != 'None'
            o.group = _split(value)
        when 'Provides'
          if value != 'None'
            o.provide = _parse_dep(_split(value))
        when 'Depends On'
          if value != 'None'
            o.dep = _parse_dep(_split(value))
        when 'Optional Deps'
          o.opt_dep = []
          flag_opt_dep = true
          _parse_opt_dep value
        when 'Conflicts With'
          if value != 'None'
            o.conflict = _split(value)
        when 'Replaces'
          if value != 'None'
            o.replace = _parse_dep(_split(value))
        # else: ignore
  o


# call pacman command
_call_pacman = (args) ->
  c = [config.BIN_PACMAN].concat args
  # ignore error (exit_code != 0)
  await _async.call_cmd c, true

# $ pacman -Q
get_installed_pkg_list = ->
  r = await _call_pacman ['-Q']
  _p_pkg_list r

# $ pacman -Qg
get_installed_group_list = ->
  r = await _call_pacman ['-Qg']
  _p_i_group_list r

# eg: $ pacman -Sg gnome-extra
get_group_info = (group_name) ->
  r = await _call_pacman ['-Sg', group_name]
  _p_group_info r

get_group_info_list = (group_name_list) ->
  r = await _call_pacman ['-Sg'].concat(group_name_list)
  _p_group_info_list r, group_name_list

# eg: $ pacman -Si python
# TODO FIXME $ pacman -Qi python
get_pkg_info = (pkg_name) ->
  # TODO FIMXE -Qi as fallback
  r = await _call_pacman ['-Si', pkg_name]
  _p_pkg_info r

get_pkg_info_list = (pkg_name_list) ->
  r = await _call_pacman ['-Si'].concat(pkg_name_list)
  _p_pkg_info_list r, pkg_name_list

# $ pacman -Qm
get_user_pkg_list = ->
  r = await _call_pacman ['-Qm']
  _p_pkg_list r

# $ pacman -Qe
get_user_roots = ->
  r = await _call_pacman ['-Qe']
  _p_pkg_list r


# gen pacman command
# eg: # pacman --remove ruby php
gen_remove_command = (pkg_list) ->
  list = pkg_list.join ' '
  "# pacman --remove #{list}"

# eg: # pacman -S --needed git atom
gen_install_command = (pkg_list) ->
  list = pkg_list.join ' '
  "# pacman -S --needed #{list}"


module.exports = {
  get_installed_pkg_list  # async
  get_installed_group_list  # async
  get_group_info  # async
  get_group_info_list  # async
  get_pkg_info  # async
  get_pkg_info_list  # async

  get_user_pkg_list  # async
  get_user_roots  # async

  gen_remove_command
  gen_install_command
}
