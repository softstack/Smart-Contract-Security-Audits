============================
A PythX-driven CLI for MythX
============================


.. image:: https://img.shields.io/pypi/v/mythx-cli.svg
    :alt: MythX CLI on PyPI
    :target: https://pypi.python.org/pypi/mythx-cli

.. image:: https://img.shields.io/github/license/dmuhs/mythx-cli
    :alt: MythX CLI License
    :target: https://github.com/dmuhs/mythx-cli/blob/master/LICENSE

.. image:: https://img.shields.io/travis/dmuhs/mythx-cli.svg
    :alt: MythX CLI Build Status
    :target: https://travis-ci.org/dmuhs/mythx-cli

.. image:: https://coveralls.io/repos/github/dmuhs/mythx-cli/badge.svg?branch=master
    :alt: MythX CLI Coverage Stats
    :target: https://coveralls.io/github/dmuhs/mythx-cli?branch=master

.. image:: https://readthedocs.org/projects/mythx-cli/badge/?version=latest
    :alt: Documentation Status
    :target: https://mythx-cli.readthedocs.io/

.. image:: https://img.shields.io/pypi/dm/mythx-cli
    :alt: PyPI - Downloads
    :target: https://pypi.python.org/pypi/mythx-cli


This package aims to provide a simple to use command line interface for the `MythX <https://mythx.io/>`_ smart contract
security analysis API. It's main purpose is to demonstrate how advanced features can be implemented using the
`PythX <https://github.com/dmuhs/pythx/>`_ Python language bindings for MythX to simplify API interaction.


What is MythX?
--------------

MythX is a security analysis API that allows anyone to create purpose-built security tools for smart
contract developers. Tools built on MythX integrate seamlessly into the development environments and
continuous integration pipelines used throughout the Ethereum ecosystem.


Usage
-----

.. code-block:: console

    $ mythx
    Usage: mythx [OPTIONS] COMMAND [ARGS]...

      Your CLI for interacting with https://mythx.io/

    Options:
      --debug                         Provide additional debug output
      --api-key TEXT                  Your MythX API key from the dashboard
      --username TEXT                 Your MythX account's username
      --password TEXT                 Your MythX account's password
      --format [simple|json|json-pretty|table]
                                      The format to display the results in
                                      [default: table]
      --ci                            Return exit code 1 if high-severity issue is
                                      found
      -y, --yes                       Do not prompt for any confirmations
      -o, --output TEXT               Output file to write the results into
      --help                          Show this message and exit.

    Commands:
      analysis  Get information on running and finished analyses.
      analyze   Analyze the given directory or arguments with MythX.
      group     Create, modify, and view analysis groups.
      render    Render an analysis job or group report as HTML.
      version   Display API version information.



Installation
------------

The MythX CLI runs on Python 3.6+, including 3.8 and pypy3.

To get started, simply run

.. code-block:: console

    $ pip3 install mythx-cli

Alternatively, clone the repository and run

.. code-block:: console

    $ pip3 install .

Or directly through Python's :code:`setuptools`:

.. code-block:: console

    $ python3 setup.py install



* Free software: MIT license
* Documentation: https://mythx-cli.readthedocs.io.
