# config.coffee, pkg_cleaner/src/

PKGC_MARK = 'uuid=6fef1e4a-92a6-4cb3-bb7f-25e99f4cf04f'
PKGC_VERSION = 'pkg_cleaner version 0.1.0-1 test20170419 1609'

PKGC_DB_VERSION = 'pkgc pkg_info db version 0.1.0-1'
PKGC_RULE_VERSION = '0.1.0-1'

BIN_PACMAN = 'pacman'

module.exports = {
  PKGC_MARK
  PKGC_VERSION
  PKGC_DB_VERSION
  PKGC_RULE_VERSION

  BIN_PACMAN

  # global config
  pkg_db_file: 'tmp/pkgc_db.json'
  rule_list: 'tmp/pkgc_list.json'
}
