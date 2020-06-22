=======
History
=======

0.6.18 (2020-06-16)
-------------------

- Update :code:`pythx` to 1.6.1 to fix validation errors


0.6.17 (2020-06-16)
-------------------

- Add experimental Scribble integration for property validation
- Remove bytecode payload option due to lack of usage
- Require users to explicitly consent to analysis submission
- Add feature that allows users to force a certain analysis scenario
- Clean up code into payload-related job objects
- Fix issue where pypy7.1.1-beta0 doesn't support PathLike in os.chdir
- Slim down Solidity file walking logic
- Refresh payload documentation
- Refactor payload-related tests
- Update :code:`py-solc-x` to 0.9.0
- Update :code:`5.4.3`
- Update :code:`sphinx` to 3.1.1
- Update :code:`pytest-cov` to 2.10.0
- Update :code:`tox` to 3.15.2


0.6.16 (2020-05-15)
-------------------

- Whitelist OSX solc installations in :code:`py-solc-x`
- Update :code:`bumpversion` to 0.6.0


0.6.15 (2020-05-12)
-------------------

- Fix bug where payload path prefix trimming was incorrect
- Generate source list from Truffle artifact files
- Improve Solidity file walk performance
- Refactor payloads submodule
- Update :code:`tox` to 3.15.0
- Update :code:`pytest` to 5.4.2
- Update :code:`py-solc-x` to 0.8.2


0.6.14 (2020-04-30)
-------------------

- Fix bug where location offsets were incorrectly displayed in reports
- Fix bug where whitespace was incorrectly rendered in HTML reports
- Clean up HTML report layout template code
- Update :code:`click` to 7.1.2


0.6.13 (2020-04-27)
-------------------

- Add property verification flag docs
- Add property checking flag to analyze command
- Update :code:`sphinx` to 3.0.3


0.6.12 (2020-04-20)
-------------------

- Fix bug where new line characters were incorrectly sent on Windows OS
- Fix bug where group creation from config was not triggered
- Update :code:`sphinx` to 3.0.2
- Update :code:`coverage` to 5.1
- Update :code:`Jinja` to 2.11.2


0.6.11 (2020-04-08)
-------------------

- Use solc JSON stdin for compilation
- Update :code:`sphinx` to 3.0.0
- Update :code:`coveralls` to 2.0.0


0.6.10 (2020-04-03)
-------------------

- Add :code:`--api/--self` version command switch
- Add explicit yaml config override feature
- Documentation updates
- Update :code:`tox` to 3.14.6
- Update :code:`py-solc-x` to 0.8.1


0.6.9 (2020-03-24)
------------------

Fix issue where request source list was malformed


0.6.8 (2020-03-23)
------------------

- Add support for :code:`.mythx.yml` config files
- Allow pwd definitions in solc import remappings
- Fix bug in Solidity file walking routine
- Add additional tox checks for documentation and formatting


0.6.7 (2020-03-19)
------------------

Fix issue where render templates were not correctly added to manifest.


0.6.6 (2020-03-19)
------------------

- Refactor commands into dedicated packages
- Fix bug where click commands were not picked up by autodoc
- Fix bug where :code:`render` command log cluttered report stdout
- Add support for upper case targets in :code:`render` command
- Add more verbose debug logging across package


0.6.5 (2020-03-17)
------------------

- Add optional contract name specification for Solidity files
- Revise usage and advanced usage docs for solc compilation
- Add :code:`--remap-import` parameter for solc import remappings
- Update :code:`coverage` to 5.0.4


0.6.4 (2020-03-15)
------------------

- Add :code:`--include` flag to :code:`analyze` subcommand
- Fix minor bug in package description content type definition
- Update :code:`tox` to 3.14.5
- Update :code:`sphinx` to 2.4.4
- Update :code:`py-solc-x` to 0.8.0
- Update :code:`click` to 7.1.1
- Update :code:`pytest` 5.4.1


0.6.3 (2020-02-15)
------------------

- Update :code:`sphinx` to 2.4.1
- Improved Usage Guide documentation
- Added more verbose descriptions in Advanced Usage guide
- Add improved Python docstrings, enforce formatting
- Add more precise type hints across the code base
- Fix bug where Solidity payloads were truncated
- Add :code:`mythx render --markdown` parameter for md reports
- Add :code:`rglob` blacklist to exclude :code:`node_modules` during .sol directory walks


0.6.2 (2020-02-08)
------------------

- Update :code:`pytest` to 5.3.5
- Add :code:`mythx render` subcommand for HTML report rendering
- Various HTML template improvements
- Add :code:`Jinja2` and :code:`htmlmin` dependencies
- Add documentation for custom template creation
- Add filtering of Solidity payloads without compiled code (e.g. interfaces)


0.6.0 & 0.6.1 (2020-01-29)
--------------------------

- Add unified reports (e.g. :code:`json` output of multiple reports in a single JSON object)
- Add SWC ID whitelist parameter to report filter
- Integrate report filters with :code:`--ci` flag
- Add advanced usage guide to documentation
- Improved messaging across CLI
- Update :code:`pytest` to 5.3.4
- Improve test suite assertion diff display


0.5.3 (2020-01-16)
------------------

- Bump :code:`py-solc-x` to 0.7.0


0.5.2 (2020-01-16)
------------------

- Fix merge release mistake (yeah, sorry.)


0.5.1 (2020-01-16)
------------------

- Add support for new modes (quick, standard, deep)
- Fix issue where Truffle address placeholders resulted in invalid bytecode


0.5.0 (2020-01-14)
------------------

- Add :code:`--create-group` flag to analyze subcommand
- Add privacy feature to truncate paths in submission
- Support Truffle projects as target directories
- Add SonarQube output format option
- Revamp usage documentation
- Update coverage to 5.0.3
- Update package details


0.4.1 (2020-01-03)
------------------

- Add batch directory submission feature
- Add a :code:`--yes` flag to skip confirmation messages

0.4.0 (2020-01-02)
------------------

- Add :code:`--output` flag to print to file
- Refactor test suite
- Update coverage to 5.0.1
- Update Sphinx to 2.3.1
- Update tox to 3.14.3

0.3.0 (2019-12-16)
------------------

- Add links to MythX dashboard in formatters
- Add support for analysis groups
- Split up logic in subcommands (analysis and group)
- Add CI flag to return 1 on high-severity issues
- Add parameter to blacklist SWC IDs
- Fix bug where :code:`--solc-version` parameter did not work
- Refactor test suite
- Update pytest to 5.3.1
- Update Sphinx to 2.3.0

0.2.1 (2019-10-04)
------------------

- Update PythX to 1.3.2

0.2.0 (2019-10-04)
------------------

- Update PythX to 1.3.1
- Add tabular format option as new pretty default
- Update pytest to 5.2.0
- Various bugfixes

0.1.8 (2019-09-16)
------------------

- Update dependencies to account for new submodules

0.1.7 (2019-09-16)
------------------

- Update pythx from 1.2.4 to 1.2.5
- Clean stale imports, fix formatting issues

0.1.6 (2019-09-15)
------------------

- Improve CLI docstrings
- Add more formatter-related documentation

0.1.5 (2019-09-15)
------------------

- Add autodoc to Sphinx setup
- Add middleware for tool name field
- Enable pypy3 support
- Add more verbose documentation
- Allow username/password login

0.1.4 (2019-09-13)
------------------

- Fix Atom's automatic Python import sorting (broke docs)

0.1.3 (2019-09-13)
------------------

- Fix faulty version generated by bumpversion

0.1.2 (2019-09-13)
------------------

- Fix bumpversion regex issue

0.1.1 (2019-09-13)
------------------

- Initial implementation
- Integrated Travis, PyUp, PyPI upload

0.1.0 (2019-08-31)
------------------

- First release on PyPI.
