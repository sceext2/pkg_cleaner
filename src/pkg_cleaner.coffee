# pkg_cleaner.coffee, pkg_cleaner/src/
config = require './config'

_print_help = ->
  console.log '''
  pkg_cleaner: Remove unneeded packages
  Usage:
      --gen-db   Generate pkg database
      --analyse  Start analyse

      --help     Show this help text
      --version  Show version of this program

  pkg_cleaner: <https://github.com/sceext2/pkg_cleaner>
  '''

_print_version = ->
  console.log config.PKGC_VERSION

main = (argv) ->
  switch argv[0]
    when '--gen-db'
      await require('./sub/gen_db')()
    when '--analyse'
      await require('./sub/analyse')()

    when '--help'
      _print_help()
    when '--version'
      _print_version()
    else
      console.log "ERROR: bad command line, please try `--help` "
      process.exit(1)

_start = ->
  try
    await main(process.argv[2..])
  catch e
    # DEBUG
    console.log "ERROR: #{e.stack}"
    # FIXME
    #throw e
    process.exit(1)
_start()
