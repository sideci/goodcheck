# Changelog

## HEAD

## 3.0.1 (2021-06-14)

* Retry HTTP GET request on importing rules [#197](https://github.com/sider/goodcheck/pull/197)

## 3.0.0 (2021-06-14)

Breaking changes:

* Drop support of Ruby 2.4 [#169](https://github.com/sider/goodcheck/pull/169)
* `goodcheck test` exit with `3` on tests failed [#168](https://github.com/sider/goodcheck/pull/168)
  (a potentially breaking change; the command previously exited with `1`)

Features:

* Import `.tar.gz` files [#190](https://github.com/sider/goodcheck/pull/190)
* Introduce `exclude_binary` option [#195](https://github.com/sider/goodcheck/pull/195)
* Add rule severity [#172](https://github.com/sider/goodcheck/pull/172)

Bugfixes and others:

* Update gemspec [#176](https://github.com/sider/goodcheck/pull/176)
* Update `psych` requirement allowing 4.0 [#183](https://github.com/sider/goodcheck/pull/183)
* Improve output error message on `RegexpError` [#188](https://github.com/sider/goodcheck/pull/188)
* Fix importing error with extended glob [#194](https://github.com/sider/goodcheck/pull/194)

## 2.7.0 (2020-12-02)

* Goodbye ActiveSupport [#155](https://github.com/sider/goodcheck/pull/155)
* Fix zero column [#160](https://github.com/sider/goodcheck/pull/160)
* Improve text reporter [#161](https://github.com/sider/goodcheck/pull/161)

## 2.6.1 (2020-11-19)

* Add missing doc for importing glob feature [#151](https://github.com/sider/goodcheck/pull/151)
* Renewal documentation [#152](https://github.com/sider/goodcheck/pull/152)

## 2.6.0 (2020-11-17)

* Improve CLI help and error messages [#141](https://github.com/sider/goodcheck/pull/141)
* Fail if missing rules on `goodcheck check` command [#142](https://github.com/sider/goodcheck/pull/142)
* Reduce needless files in this gem [#143](https://github.com/sider/goodcheck/pull/143)
* Add `Goodcheck::Error` as a base error class [#144](https://github.com/sider/goodcheck/pull/144)
* Improve error message when config file is not found [#145](https://github.com/sider/goodcheck/pull/145)
* Add `rules[].glob.exclude` option to `goodcheck.yml` [#146](https://github.com/sider/goodcheck/pull/146)
* Glob support for importing rules [#149](https://github.com/sider/goodcheck/pull/149)

## 2.5.2 (2020-08-31)

* Fix the pattern of disable lines for Slash-asterisk and add support for JSX [#131](https://github.com/sider/goodcheck/pull/131)

## 2.5.1 (2020-03-09)

* Replace `httpclient` with `net/http` [#115](https://github.com/sider/goodcheck/pull/115)

## 2.5.0 (2020-02-27)

* Add disable lines via inline comments [#101](https://github.com/sider/goodcheck/pull/101) (thanks to [@dcwither](https://github.com/dcwither)). See [README](https://github.com/sider/goodcheck#disabling-rules-with-inline-comments) for details.

## 2.4.5 (2019-12-13)

* Replace ActiveSupport's `Regexp#multiline?` extension [#97](https://github.com/sider/goodcheck/pull/97) (thanks to [@issei126](https://github.com/issei126))

## 2.4.4 (2019-11-19)

* Check dot files (except for `.git`, `.svn`, `.hg`) [#91](https://github.com/sider/goodcheck/pull/91)
* Improve `test` command output [#93](https://github.com/sider/goodcheck/pull/93)

## 2.4.3 (2019-11-07)

* Change LICENSE to MIT [#76](https://github.com/sider/goodcheck/pull/76)

## 2.4.2 (2019-10-24)

* Fix `check` error on empty files [#73](https://github.com/sider/goodcheck/pull/73)

## 2.4.1 (2019-08-29)

* Relax dependency requirement for ActiveSupport [#68](https://github.com/sider/goodcheck/pull/68)

## 2.4.0 (2019-07-11)

* Add `pattern` command to print regexp of patterns [#63](https://github.com/sider/goodcheck/pull/63)
* Fix variable pattern without a type [#62](https://github.com/sider/goodcheck/pull/62)

## 2.3.2 (2019-07-04)

* Update README

## 2.3.1 (2019-07-03)

* Fix Docker image [#59](https://github.com/sider/goodcheck/pull/59)

## 2.3.0 (2019-07-02)

* Fix Docker image [#58](https://github.com/sider/goodcheck/pull/58)

## 2.2.0 (2019-06-25)

* Allow testing numeric variables with regexp

## 2.1.2 (2019-06-14)

* Let `rules` in configuration be optional

## 2.1.1 (2019-06-11)

* Let `:int` variable match with `0`

## 2.1.0 (2019-06-10)

* Introduce regexp string pattern [#56](https://github.com/sider/goodcheck/pull/56)
* Introduce variable binding token pattern [#55](https://github.com/sider/goodcheck/pull/55)

## 2.0.0 (2019-06-06)

* Introduce trigger, a new pattern definition [#53](https://github.com/sider/goodcheck/pull/53)

## 1.7.1 (2019-05-29)

* Fix test command error handling
* Update strong_json

## 1.7.0 (2019-05-28)

* Support a rule without `pattern` [#52](https://github.com/sider/goodcheck/pull/52)
* Let each `pattern` have `glob` [#50](https://github.com/sider/goodcheck/pull/50)

## 1.6.0 (2019-05-08)

* Add `not` pattern rule [#49](https://github.com/sider/goodcheck/pull/49)

## 1.5.1 (2019-05-08)

* Regexp matching improvements
* Performance improvements

## 1.5.0 (2019-03-18)

* Add `exclude` option #43

## 1.4.1 (2018-10-15)

* Update StrongJSON #28

## 1.4.0 (2018-10-11)

* Exit with `2` when it find matching text #27
* Import rules from another location #26

## 1.3.1 (2018-08-16)

* Delete Gemfile.lock

## 1.3.0 (2018-08-16)

* Improved commandline option parsing #25 (@ybiquitous)
* Skip loading dot-files #24 (@calancha)
* Performance improvement on literal types #15 (@calancha)

## 1.2.0 (2018-06-29)

* `case_insensitive` option is now renamed to `case_sensitive`. #4
* Return analysis JSON object from JSON reporter. #13 (@aergonaut)

## 1.1.0 (2018-05-16)

* Support `{}` syntax in glob. #11
* Add `case_insensitive` option for `token` pattern. #10

## 1.0.0 (2018-02-22)

* Stop resolving realpath for symlinks. #6
* Revise non-ASCII characters tokenization. #5

## 0.3.0 (2017-12-27)

* `check` ignores config file unless explicitly given by commandline #2

## 0.2.0 (2017-12-26)

* Add `version` command
