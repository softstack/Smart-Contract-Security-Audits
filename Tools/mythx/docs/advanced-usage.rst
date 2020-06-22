==============
Advanced Usage
==============

The purpose of this document is to give an introduction to advanced usage patterns
of the MythX CLI as well as functionality the user might not have been aware of.


Automatic Group Creation
------------------------

The basic workflow for attaching analyses to groups can be divided into the following
steps:

1. Open a new group with :code:`mythx group open`
2. Submit analyses in reference to the new group :code:`mythx analyze --group-id <ID>`
3. Close the group when done :code:`mythx group close <ID>`

This can become very annoying and hinder automation tasks leveraging the MythX CLI.
Because of that, the :code:`--create-group` flag has been introduced. Passing this
flag to :code:`mythx analyze` will automatically open a group before submitting new
analysis jobs, and close it after the submission process has been completed. This
functionality encapsulates all targets passed to the :code:`analyze` subcommand.

A short example:

.. code-block:: console

    $ mythx analyze --create-group dir1/ test.sol test2.sol

This command will initialize an empty group, add all analyses coming from :code:`dir1/`
and the two test Solidity files into it, and close it once submission has been completed.
The analyses will then show up in their dedicated group inside the dashboard.


File Output
-----------

Especially in scenarios of automation the need often arises to persist data and store it
as files. Since version :code:`0.4.0` the base :code:`mythx` command carries the
:code:`--output` option. This allows you to take the :code:`stdout` from any subcommand
and store it as a file. This can be very helpful for storing analysis job and group IDs
for long-running asynchronous jobs - which we will also outline in this document.

The :code:`--format` option is fully supported with :code:`--output` and allows the user
to define what is written to the file. Furthermore, it can be combined with every
subcommand :code:`mythx` supports.

Examples:

1. :code:`mythx --output=status.json --format=json-pretty status <id>`: Output the status of
   an analysis job in pretty-printed JSON format to :code:`status.json`.
2. :code:`mythx --output=report.json --format=json report report <id>`: This is equivalent as
   above with the difference being that now the analysis job's report is fetched and directly
   written to the file. This is especially useful for testing new formatters and other
   integrations with static input.
3. :code:`mythx --output=analyses.txt analyze --async <targets>`: This performs a quick analysis
   on the defined targets (e.g. truffle projects, Solidity files) and instead of waiting for the
   results, simply writes the analysis job IDs to the :code:`analyses.txt` files. This can be
   helpful for when you need to persist long-running analysis IDs and cannot wait for them to
   finish, e.g. when running full-mode analyses on a CI server.


Filtering Reports
-----------------

The MythX CLI offers a variety of flags to filter report output. These are available in the
:code:`analyze` and :code:`report` subcommands respectively and identical in their behaviour.
Report filtering can be used to hide unwanted issues detected by MythX, e.g. a floating Solidity
compiler pragma (`SWC-103 <https://swcregistry.io/docs/SWC-103>`_). There are three flags with
report filtering capabilities available:

1. :code:`--swc-blacklist`: Ignore specific SWC IDs, e.g. :code:`--swc-blacklist SWC-104` will
   display all found issues except for unchecked call return values.
2. :code:`--swc-whitelist`: Ignore all SWC IDs that do not match the given ones, e.g.
   :code:`--swc-whitelist 110,123` will only display requirement and assert violations.
3. :code:`--min-severity`: Ignore issues below the given severity, e.g. :code:`--min-severity medium`
   ignores all low severity issues.

The SWC black- and whitelist parameters support a variety of formats. Besides individual SWC IDs, the
user can also pass in a comma-separated list of multiple IDs to submit a list. Furthermore, the inputs
can be expressed in different manners, i.e. :code:`swc-110`, :code:`SWC-110`, and :code:`110` all target
the same SWC ID. List submission works in the same way, so :code:`--swc-blacklist=SWC-101,102,swc-103` is
a valid way to exclude IDs 101-103 from the report, even though it is definitely recommended to stick with
a consistent notation for readability purposes.


Property Verification Mode
--------------------------

To leverage MythX for property verification, simply pass the :code:`--check-properties` flag to the
:code:`analyze` subcommand. This will instruct the MythX analysis backend to only look for assertion
violations and optimize execution.


Asynchronous Analysis
---------------------

As mentioned before, the :code:`analyze` subcommand offers the :code:`--async` flag. This will prevent
the CLI from blocking after the submission of one or multiple analysis jobs and waiting for them to finish.
Instead, for each analysis job the job's UUID will be printed to :code:`stdout`, or to a file, if the
:code:`--output` option is passed as well. This feature is often used in CI scenarios, where the server
job is not expected to run for very long. It is strongly recommended that this flag is used in combination
with MythX plans that offer higher analysis times. These scans are more exhaustive, deliver more precise
results, but as a trade-off take longer to process. In the CI server scenario, a developer might choose to
submit analyses asynchronously and check on the job later in the MythX dashboard. Alternatively, the job
IDs could also be stored in a file as a CI artifact and later retrieved by another part of the pipeline,
e.g. to kickstart a security or QA pipeline.

An example is the submission of a large truffle project:

.. code-block:: console

    $ mythx analyze --async my-project/

This flag is also best friends with the :code:`--create-group` flag for the :code:`analyze` subcommand. Together
they help keeping the MythX dashboard overview tidy.


The CI Flag
-----------

MythX is designed to support developers throughout the process of building their product by providing
continuous security checks. It is self-understood that CI use cases present their own set of challenges,
and the MythX CLI aims to support this process by providing the `--ci` flag in the base command. This
flag sets the application's return code to 1 if any issues were found in the analysis.

The true power of this flag becomes apparent when taking into consideration that it is fully integrated
with the options available for report filtering. This means that the return code can be set depending on
the input provided to the :code:`swc-blacklist`, :code:`swc-whitelist`, and :code:`min-severity` options.
A use case is to make CI jobs only fail on high-severity issues, but excluding a subset of them because
they are already in the process of being fixed, or insignificant relating to the business logic.

The filtering options can be freely combined with the :code:`--ci` flag to achieve the desiged behaviour.
A simple example is excluding the (fairly common) floating pragma issue type, and assert and requirement
violations for testing purposes:

.. code-block:: console

    $ mythx --ci analyze --swc-blacklist 110,123,103 my-project/


Import Remapping and Relative Paths in solc
-------------------------------------------

When given one or more Solidity files as argument, the MythX CLI will try to compile them using solc to
submit the resulting bytecode, AST, and source mappings. Especially in more complex smart contract systems,
contract dependencies such as zOS and OpenZeppelin libraries are pulled in using NPM. These can then be
imported using
`import remappings <https://ethereum.stackexchange.com/questions/71222/importing-sol-files-from-an-node-modules-folder>`_
in the solc call. These remappings are supported by the MythX CLI as well. Given some example Solidity
imports that would make standard compilation fail:

.. code-block:: text

    import "openzeppelin-zos/contracts/token/ERC721/ERC721Token.sol";
    import "openzeppelin-zos/contracts/token/ERC721/ERC721Receiver.sol";
    import "openzeppelin-zos/contracts/ownership/Ownable.sol";

These imports will have to be remapped. This can be done by passing the :code:`--remap-import` parameter
to the :code:`analyze` call:

.. code-block:: console

    $ mythx analyze --remap-import "openzeppelin-zos/=$(pwd)/node_modules/openzeppelin-zos/" myContract.sol

This parameter can be defined multiple times to declare various import remappings in the context
of the same call. If no remappings are given, the MythX CLI tries to make the user's life as easy as
possible by defining a set of remappings that should act as a sane default:

.. code-block:: text

    openzeppelin-solidity/=<pwd>/node_modules/openzeppelin-solidity/
    openzeppelin-zos/=<pwd>/node_modules/openzeppelin-zos/
    zos-lib/=<pwd>/node_modules/zos-lib

This does not affect relative imports such as

.. code-block:: text

    import "../interfaces/MyInterface.sol";

These are supported by default through the MythX CLI by adding the current working directory the
call was made from to the allowed solc paths. Please note that if compilation fails on a relative
import, the current working directory was not the project root that results in correct import
resolution.


Configuration using .mythx.yml
------------------------------

Using import remappings, contract filters, SWC black-/whitelists, and various other configuration
options can result in large CLI commands. The :code:`.mythx.yml` file can remediate this by
providing the user with an easy-to-read and -update YAML configuration file.

Top-level parameters (included after the :code:`mythx` command) are defined on the top level
of the configuration file, while analysis-specific parameters (included after the :code:`analyze`
subcommand) are included under the :code:`analyze` key. For example:

.. code-block:: yaml

    output: mythx.json
    format: json

    analyze:
        mode: quick
        create-group: true
        group-name: My fancy analysis
        solc: 0.5.16
        remappings:
            - "@openzeppelin/=/my/path/node_modules/@openzeppelin/"
            - "@nomiclabs=/my/path/node_modules/@nomiclabs/"
        contracts:
            - Contract1
            - Contract2
            - Contract3
            - Contract4
            - Contract5

This will execute a quick analysis on the five specified contracts. Compilation is done using
solc version 0.5.16 and the specified import remappings are passed to the compiler. Additionally,
a new group will be opened for this submission under the name `My fancy analysis`. After submission,
the CLI will wait until all contracts have been analyzed and output the resulting report in JSON
format. This report will be written into the :code:`mythx.json` file. In a CI scenario, this report
could for example be stored as an artifact for later retrieval and further processing.

The currently supported top-level configuration keys are:

- :code:`ci`: Boolean indicating whether to return 1 if any severe issue is found
  (equivalent to :code:`--ci`)
- :code:`output`: Name of the file to write output data into (equivalent to :code:`--output`)
- :code:`format`: The output format to return (equivalent to :code:`--format`)
- :code:`confirm`: Boolean indicating the automatic confirmation of multiple file submissions
  (equivalent to :code:`--yes`)

The :code:`analyze` configuration keys currently supported are:

- :code:`mode`: The analysis mode to run MythX on (equivalent to :code:`--mode`)
- :code:`create-group`: Boolean indication whether to create a new group for the submission
  (equivalent to :code:`--create-group`)
- :code:`group-id`: The group ID to add the submitted analyses to (equivalent to :code:`--group-id`)
- :code:`group-name`: The name to attach to the newly created group (equivalent to :code:`--group-name`)
- :code:`min-severity`: Ignore SWC IDs below the designated level (equivalent to :code:`--min-severity`)
- :code:`blacklist`: A comma-separated list of SWC IDs to ignore (equivalent to :code:`--swc-blacklist`)
- :code:`whitelist`: A comma-separated list of SWC IDs to include (equivalent to :code:`--swc-whitelist`)
- :code:`async`: A boolean indicating whether to submit the analyses asynchronously
  (equivalent to :code:`--async`)
- :code:`solc`: The solc version to use for Solidity file compilation (equivalent to :code:`--solc-version`)
- :code:`remappings`: A list of import remappings to pass to the solc compiler (equivalent to one or
  multiple :code:`--remap-import` parameter(s))
- :code:`contracts`: A list of contracts to include in the submission (equivalent to one or
  multiple :code:`--include` parameter(s))
- :code:`check-properties` Enable property verification mode (filter out everything other than assertion
  violations in the backend and optimize for property verification)
- :code:`targets`: A list of targets to analyze. This is equivalent to passing an argument directly to
  the :code:`analyze` command - whether it's a Solidity file, a directory, a Truffle project, or a mix
  of all.


Property Validation with Scribble
---------------------------------

Scribble is a tool develped by `ConsenSys Diligence <https://diligence.consensys.net/>`_ that aims to
facilitate verification of invariants over smart contract systems. This is done by annotating parts
of the Solidity code with instrumentation comments. Scribble as a tool then translates the user-provided
specifications into an instrumented smart contract that can be sent to MythX. The MythX analysis tools
will then specifically look for assertion violations that break the defined invariants and generate a
report outlining how they were broken.

Scribble is currently in its early alpha version. The MythX CLI still aims to natively provide a
Scribble integration to make property validation of Solidity smart contracts as easy as possible. At the
moment it is integrated into the :code:`analyze` subcommand and can be accessed as follows:

.. code-block:: console

    $ mythx analyze --scribble annotated_token.sol
    Found 1 job(s). Submit? [y/N]: y
      [####################################]  100%
    Report for scribble-annotated_token.sol
    https://dashboard.mythx.io/#/console/analyses/9a2c4e24-0c9d-4834-b11f-fb99061ba910
    ╒════════╤══════════════════╤════════════╤═══════════════════════════════════════╕
    │   Line │ SWC Title        │ Severity   │ Short Description                     │
    ╞════════╪══════════════════╪════════════╪═══════════════════════════════════════╡
    │     41 │ Assert Violation │ Medium     │ An assertion violation was triggered. │
    ╘════════╧══════════════════╧════════════╧═══════════════════════════════════════╛


To view the details on how the invariant was violated, check out the report details on the
dashboard, or switch to a different output format, such as :code:`json-pretty`.


Custom Report Rendering
-----------------------

The MythX CLI exposes a subcommand :code:`render`, which allows the user to generate HTML reports of the
analyses inside a group, or an individual analysis job. The :code:`--template` flag allows the user to
submit their own report template. This bears the question: How is a custom template written? This section
aims to explain the two ways of writing a custom template:

1. Write a new template from scratch
2. Extend the default :code:`layout.html` or :code:`layout.md` with the pre-defined blocks


Writing a New Template From Scratch
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Is the default layout too complex? Do block names confuse you? No worries! The MythX CLI of course
also support completely user-defined templates. These templates can be specified using
`the Jinja2 syntax <https://jinja.palletsprojects.com/>`_. With basic knowledge of HTML, CSS, Jinja, and
possibly also JavaScript (if you feel fancy), it is fairly easy to write a template. Explaining the
inner workings of Jinja and the core principles of web design are out of scope for this section.
It is relevant to know what context MythX provides for user-defined templates. There are two core
items that are rendered onto the template. The :code:`issues_list`, and the :code:`target`.

The :code:`target` is a string containing either the analysis group ID, or the analysis job UUID
that the user has passed to the :code`render` subcommand.

The :code:`issues_list` is a list of tuples. Each tuple contains three elements. These are in order:
1. The analysis' status model object
2. The analysis' issue report object
3. The analysis' input model object

These objects along with their methods and properties can be looked up in the
`MythX domain model package <https://mythx-models.readthedocs.io/>`_. Generating a simple report is
as easy as iterating over the :code:`issues_list` parameter and displaying the properties of each
tuple element in the desired way:

.. code-block:: jinja

    {% for status, report, input in issues_list %}
    {# my template code #}


Extending the Default HTML Template
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The MythX CLI default template is generated from two files: :code:`layout.html` and :code:`default.html`.
The former defines the overall structure of the report page, namely the
`CSS grid <https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout>`_ and the components built
on top of it. The latter template extends the layout file and adds the default theme's color scheme and
fonts.

In `Jinja2 <http://jinja.palletsprojects.com/>`_, the templating language used by the report renderer,
templates can be extended by defining so-called blocks in the template file to be extended. Blocks can
contain content already to define a sane default. Otherwise, the extending template can choose to
overwrite specific blocks of the extended templates to inject customized content. This is a powerful
mechanic that is extensively used by the report rendering engine. A short example:

Let's assume we have a base template :code:`base.html` that defines the following code in its HTML head
tag:

.. code-block:: jinja

    <head>
        <title>{% block title %}Default{% endblock %}</title>
    </head>

An extending template :code:`extended.html` might them contain the following code:

.. code-block:: jinja

    {% extends "base.html" %}
    {% block title %}My Extended Title{% endblock %}

In the final template, we will get the combined code:

.. code-block:: html

    <head>
        <title>My Extended Title</title>
    </head>

The advantages here are obvious: By providing a sane default template with reasonable
block definitions, the MythX CLI can allow the user to make quick and rather deep updates
to the final HTML template without them needing to go through the hassle of reading and
understanding the HTML, CSS, and Jinja statements written in the overall default template
- even though this knowledge becomes more useful the deeper the user aims to change things up.

More details can be found in the official `Jinja template inheritance docs
<https://jinja.palletsprojects.com/en/2.11.x/templates/#template-inheritance>`_.

All blocks in the default template are scoped, meaning that the extending template has access
to all context variables around the block in the base template file. This allows the user to
e.g. access report objects inside the block from the extending layout to customize the way
things are displayed. The blocks defined in the layout template are as follows:

- :code:`head`
    Defines the :code:`head` HTML tag. This will overwrite all default content
    including CSS styles and the site title.
- :code:`style`
    Defines the CSS styles. If you want to keep the default template's style,
    consider using :code:`{{ super() }}` insite the extending block definition to insert the
    styles from the parent template.
- :code:`title`
    Defines the site title as it appears in the Browser tab and header.
- :code:`extra_html`
    This is a block that is empty by default. It allows the user to insert
    extra HTML tags at the beginning of the body element - before anything else is defined.
    This is expecially useful for overlays, but with the flexibility of custom CSS styles for
    the inserted element, it can be positioned elsewhere in absolute terms,
- :code:`navigation`
    Defines the content of the navigation bar on the left-hand side of the page. It should
    contain an overview of all the reports inside the template and allow the user to click
    on a navigation link that jumps directly to the selected analysis report.
- :code:`navigation_header`
    Defines the heading (:code:`h2`) of the navigation bar. By default it is defined as
    :code:`Overview`.
- :code:`main_header`
    Defines the content of the main header (a :code:`header` tag with class :code:`main-head`).
    This tag is displayed on top of the main page's report listing. If only the name needs to
    be customized, it is recommended to use the :code:`main_header_name` block instead.
- :code:`main_header_name`
    Defines the main header name. It is displayed on top of the main page's report listing.
    By default it is :code:`MythX Report for {{ target }}` where the :code:`target` variable
    is the group or analysis job ID submitted by the user to the :code:`render` subcommand.
- :code:`report_header`
    Defines the report header. This is the section on top of each analysis report inside the
    main page's report listing. By default it contains a heading with the analysis job's main
    source file(s), and a small link to the official MythX dashboard's analysis report labelled
    with the analysis UUID. More fine-grained customization can be done using the blocks below.
- :code:`report_header_name`
    Defines the report header name. This is the heading on top of each report, containing the
    main source file(s) of the analysis job. By default, this heading has the analysis job's
    UUID as ID. This is done so a user can reference the tag's ID in the navigation bar to
    quickly jump to specific report listing entries.
- :code:`report_header_link`
    Defines the report link behind the the report header name. By default, this link is
    encapsulated in a :code:`small` tag and references the default MythX dashboard at
    https://dashboard.mythx.io/.
- :code:`report_header_link_name`
    Defines the report header's link name. This is the link displayed next to the heading of
    the report pointing to the official MythX dashboard. By default, the current report's UUID
    is displayed.
- :code:`section_status`
    Defines the report's status section. The purpose of this section is to give the user a quick
    overview over the vulnerabilities that have been found in a job. By default this is a table
    displaying how many vulnerabilities per severity level have been found in the report.
- :code:`section_status_high`
    Defines the column name for :code:`high` severity vulnerabilities in the analysis status
    overview. This block can be used to e.g. change the column name to its equivalent in another
    language.
- :code:`section_status_medium`
    Defines the column name for :code:`medium` severity vulnerabilities in the analysis status
    overview. This block can be used to e.g. change the column name to its equivalent in another
    language.
- :code:`section_status_low`
    Defines the column name for :code:`low` severity vulnerabilities in the analysis status
    overview. This block can be used to e.g. change the column name to its equivalent in another
    language.
- :code:`section_status_unknown`
    Defines the column name for :code:`unknown` severity vulnerabilities in the analysis status
    overview. This block can be used to e.g. change the column name to its equivalent in another
    language.
- :code:`section_report`
    Defines the central report section of an analysis job in the main page's report listing. By
    default this section displays a table is displayed showing the SWC-IDs of the found
    vulnerabilities along with its verbose name, the file name it was found in, and location
    information carrying line and column number. More fine-grained customization can be done with
    the blocks below.
- :code:`section_report_id`
    Defines the SWC-ID column name in the report issues overview table. This block can be used
    to e.g. change the column name to its equivalent in another language.
- :code:`section_report_severity`
    Defines the severity column name in the report issues overview table. This block can be used
    to e.g. change the column name to its equivalent in another language.
- :code:`section_report_name`
    Defines the SWC title column name in the report issues overview table. This block can be used
    to e.g. change the column name to its equivalent in another language.
- :code:`section_report_file`
    Defines the file name column name in the report issues overview table. This block can be used
    to e.g. change the column name to its equivalent in another language. It should be noted that
    in the table data field, only source file entries of "text" source format issues are
    considered as their source list entries contain clear-text filenames. For bytecode locations,
    a Keccak256 hash of the contract's deployed bytecode would be used. To not confuse readers,
    this behaviour is omitted and skipped during the default template rendering.
- :code:`section_report_location`
    Defines the issue location column name in the report issues overview table. This block can be
    used to e.g. change the column name to its equivalent in another language.
- :code:`section_code`
    Defines the code section. By default, this section displays a listing of the source code
    (hidden behind a collapsible :code:`details` tag) where the found issues are highlighted inline.
    Furthermore, if the issue has any test cases attached to it, these will be rendered as
    collapsible items that are displayed once the user clicks on a code line that is highlighted
    with an issue. More fine-grained customization can be done using the blocks defined below.
- :code:`section_code_name`
    Defines the name of the collapsible to display the source code. This block can be used to e.g.
    change the column name to its equivalent in another language.
- :code:`section_case_name`
    Defines the name of the collapsible to display the issue test case. This block can be used to
    e.g. change the column name to its equivalent in another language.
- :code:`section_code_step_name`
    Defines the name of the collapsible to display a test case's step name. This block can be used
    to e.g. change the column name to its equivalent in another language.
- :code:`section_code_empty_name`
    Defines the name of the message that is displayed when no test cases are attached to the
    current issue. This is often the case for static analysis issues (like floating pragmas or the
    use of deprecated Solidity functions). This block can be used to e.g. change the column name to
    its equivalent in another language.
- :code:`no_issues_name`
    Defines the name of the message that is displayed when no issues were found in the report of
    this particular analysis job. This block can be used to e.g. change the column name to its
    equivalent in another language.
- :code:`footer`
    Defines the content of the footer. By default, the footer carries the class :code:`main-footer`,
    which by default has an absolute fixed position at the bottom. This block by default gives credits
    to MythX CLI, which was used to generate the report. It can be customized with the user's own
    branding. Kudos to the MythX CLI is not required, but always appreciated. :)


Extending the Default Markdown Template
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Extending the default Markdown template is considerably easier compared to extending the HTML one. This
is mainly due to the fact that Markdown is a simpler language and the resulting report does not contain
any interactive elements such as expanding sections to hide the code, or even a navigation bar to quickly
jump to reports.

To allow flexibility without rewriting the whole :code:`templates/layout.md` file are as follows:

- :code:`heading`
    This block contains the overall report's heading, such as "MythX Report for ...".
- :code:`preamble`
    This text sits right below the heading and is empty by default. It can be used to add a disclaimer,
    custom branding, report owners, timestamps, etc. to the report; Any meta information that is deemed
    to be useful in the report's context.
- :code:`header`
    This is the header that is displayed for each report in the analysis group - or the single analysis
    job (depending on the user input). It stands above the report status and issues overview and should
    describe the job displayed below.
- :code:`status`
    This block aims to give a quick overview over the report displayed in more granular detail below. By
    default it displays table showing the number of vulnerabilities MythX has found grouped by their
    severity.
- :code:`report`
    This block should give detailed information about the issue that has been found. By default, it
    contains the vulnerability title, SWC ID, Severity, the corresponding source lines, and a short
    source listing, containing one line before and after the source position. If the source line
    decoding failed, it will display :code:`undefined` as line locations and omit the source snippet.
- :code:`no_issues_name`
    This block should contain the message that is displayed when no issues were found in the report.
    It is displayed instead of the above :code:`status` and :code:`report` blocks.
- :code:`postamble`
    Similar to the :code:`preamble` block, this text is displayed at the end of the report listing.
    It can be used for displaying license texts and more verbose information that might be needed
    in the future but are not essential to the report itself. By default it displays a little heart
    and a link to the MythX CLI Github repository. Kudos are always appreciated and you have my thanks
    if you keep the credit intact during your awesome customization work. :)
