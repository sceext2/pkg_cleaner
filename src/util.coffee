# util.coffee, pkg_cleaner/src/

_async = require './_async'


_WRITE_REPLACE_FILE_SUFFIX = '.tmp'

# atomic write-replace for a file
write_file = (file_path, text) ->
  tmp_file = file_path + _WRITE_REPLACE_FILE_SUFFIX
  await _async.write_file tmp_file, text
  await _async.mv tmp_file, file_path


# run command and check exit_code is 0  (else will throw Error)
run_check = (cmd) ->
  exit_code = await _async.run_cmd cmd
  if exit_code != 0
    throw new Error "run command FAILED  (exit_code = #{exit_code})"

call_this_args = (args) ->
  o = [process.argv[0], process.argv[1]]
  o.concat args

# run (this program) with different args
call_this = (args) ->
  await run_check call_this_args(args)


# pretty-print JSON text
print_json = (data) ->
  JSON.stringify data, '', '    '


module.exports = {
  write_file  # async

  run_check  # async

  call_this_args
  call_this  # async

  print_json
}
