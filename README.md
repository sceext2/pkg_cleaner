# pkg_cleaner
Remove unneeded packages (for ArchLinux/pacman).


## Install

(Under [`ArchLinux`](https://www.archlinux.org/))

```
$ git clone https://github.com/sceext2/pkg_cleaner --single-branch --depth=1
$ cd pkg_cleaner
$ npm install
$ npm run build
```


## Usage

+ **1**. Modify your rules
  ```
  $ vim tmp/pkgc_list.json
  ```

+ **2**. Analyse with `pkg_cleaner`
  ```
  $ node dist/pkg_cleaner.js --gen-db
  $ node dist/pkg_cleaner.js --analyse
  ```

```
$ node dist/pkg_cleaner.js --help
pkg_cleaner: Remove unneeded packages
Usage:
   --gen-db   Generate pkg database
   --analyse  Start analyse

   --help     Show this help text
   --version  Show version of this program

pkg_cleaner: <https://github.com/sceext2/pkg_cleaner>
$
```


## LICENSE

`GNU GPLv3+`
