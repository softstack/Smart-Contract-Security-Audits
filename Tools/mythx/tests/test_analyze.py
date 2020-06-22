import pytest
from click.testing import CliRunner

from mythx_cli.cli import cli

from .common import mock_context

FORMAT_ERROR = (
    "Could not interpret argument lolwut as bytecode, Solidity file, or Truffle project"
)


def test_invalid():
    runner = CliRunner()

    with mock_context():
        result = runner.invoke(cli, ["analyze", "lolwut"])

    assert FORMAT_ERROR in result.output
    assert result.exit_code == 2


@pytest.mark.parametrize(
    "keyword",
    (
        "async",
        "wait",
        "mode",
        "quick",
        "standard",
        "deep",
        "create-group",
        "group-id",
        "group-name",
        "min-severity",
        "swc-blacklist",
        "swc-whitelist",
        "solc-version",
        "include",
        "remap-import",
        "check-properties",
        "scribble",
        "scribble-path",
        "scenario",
        "truffle",
        "solidity",
        "help",
    ),
)
def test_helppage_keywords(keyword):
    runner = CliRunner()

    result = runner.invoke(cli, ["analyze", "--help"])

    assert keyword in result.output
