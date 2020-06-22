import json
import os
from copy import deepcopy

import pytest
from click.testing import CliRunner
from mythx_models.response import (
    AnalysisInputResponse,
    AnalysisSubmissionResponse,
    DetectedIssuesResponse,
    Severity,
)

from mythx_cli.cli import cli

from .common import get_test_case, mock_context

EMPTY_PROJECT_ERROR = (
    "Could not find any truffle artifacts. Did you run truffle compile?"
)
TRUFFLE_ARTIFACT = get_test_case("testdata/truffle-artifact.json")
ISSUES_RESPONSE = get_test_case(
    "testdata/detected-issues-response.json", DetectedIssuesResponse
)
INPUT_RESPONSE = get_test_case(
    "testdata/analysis-input-response.json", AnalysisInputResponse
)
ISSUES_TABLE = get_test_case("testdata/detected-issues-table.txt", raw=True)
SUBMISSION_RESPONSE = get_test_case(
    "testdata/analysis-submission-response.json", AnalysisSubmissionResponse
)


def setup_truffle_project(base_path, compiled=True, switch_dir=False):
    # switch to temp dir if requested
    if switch_dir:
        os.chdir(str(base_path))

    # add truffle config file and project structure
    os.makedirs(str(base_path / "build/contracts/"))
    with open(base_path / "truffle-config.js", "w+") as conf_f:
        # we just need the file to be present
        conf_f.write("Truffle config stuff")

    # skip adding artifacts if not supposed to be compiled
    if not compiled:
        return

    # add sample truffle artifact
    with open(base_path / "build/contracts/foo.json", "w+") as artifact_f:
        json.dump(TRUFFLE_ARTIFACT, artifact_f)


def get_high_severity_report():
    issues_resp = deepcopy(ISSUES_RESPONSE)
    issues_resp.issue_reports[0].issues[0].severity = Severity.HIGH
    return issues_resp


@pytest.mark.parametrize(
    "target_given, yaml_given",
    (
        pytest.param(True, True, id="with target, with yaml"),
        pytest.param(True, False, id="with target, without yaml"),
        pytest.param(False, True, id="without target, with yaml"),
        pytest.param(False, False, id="without target, without yaml"),
    ),
)
def test_not_compiled(tmp_path, target_given, yaml_given):
    setup_truffle_project(
        tmp_path, compiled=False, switch_dir=yaml_given or not target_given
    )
    runner = CliRunner()
    args = ["analyze", str(tmp_path)] if target_given else ["analyze"]

    if yaml_given:
        with open(str(tmp_path / ".mythx.yml"), "w+") as yaml_f:
            yaml_f.write(f"analyze:\n  targets:\n    - {str(tmp_path)}")

    with mock_context():
        result = runner.invoke(cli, args, input="y\n")

    assert EMPTY_PROJECT_ERROR in result.output
    assert result.exit_code == 2


@pytest.mark.parametrize(
    "target_given",
    (pytest.param(True, id="with target"), pytest.param(False, id="without target")),
)
def test_missing_consent(tmp_path, target_given):
    setup_truffle_project(tmp_path, compiled=True, switch_dir=not target_given)
    runner = CliRunner()
    args = ["analyze", str(tmp_path)] if target_given else ["analyze"]

    with mock_context():
        result = runner.invoke(cli, args, input="n\n")

    assert result.output == "Found 1 job(s). Submit? [y/N]: n\n"
    assert result.exit_code == 0


@pytest.mark.parametrize(
    "yaml_given",
    (pytest.param(True, id="with yaml"), pytest.param(False, id="with param")),
)
def test_yaml_ci(tmp_path, yaml_given):
    setup_truffle_project(tmp_path, compiled=True, switch_dir=True)
    runner = CliRunner()

    with mock_context() as patches:
        # set up high-severity issue response
        patches[2].return_value = get_high_severity_report()
        if yaml_given:
            with open(str(tmp_path / ".mythx.yml"), "w+") as conf_f:
                conf_f.write("ci: true\n")
            args = ["analyze"]
        else:
            args = ["--ci", "analyze"]

        result = runner.invoke(cli, args, input="y\n")

    assert "Assert Violation" in result.output
    assert INPUT_RESPONSE.source_list[0] in result.output
    assert result.exit_code == 1


def test_param_yaml_override(tmp_path):
    setup_truffle_project(tmp_path, compiled=True, switch_dir=True)
    runner = CliRunner()

    with mock_context() as patches:
        # set up high-severity issue
        patches[2].return_value = get_high_severity_report()
        with open(str(tmp_path / ".mythx.yml"), "w+") as conf_f:
            conf_f.write("analyze:\n  async: true\n")

        result = runner.invoke(cli, ["analyze", "--wait"], input="y\n")

        assert INPUT_RESPONSE.source_list[0] in result.output
        assert result.exit_code == 0


@pytest.mark.parametrize(
    "params,value,contained,retval",
    (
        pytest.param(
            ["analyze", "--async"],
            SUBMISSION_RESPONSE.analysis.uuid,
            True,
            0,
            id="async",
        ),
        pytest.param(["analyze"], ISSUES_TABLE, True, 0, id="issue table"),
        pytest.param(
            ["analyze", "."], ISSUES_TABLE, True, 0, id="issue table with path"
        ),
        pytest.param(
            ["analyze", "."], ISSUES_TABLE, True, 0, id="valid include with path syntax"
        ),
        pytest.param(
            ["analyze", "--create-group"], ISSUES_TABLE, True, 0, id="create group"
        ),
        pytest.param(
            ["analyze", "--create-group", "."],
            ISSUES_TABLE,
            True,
            0,
            id="create group with path",
        ),
        pytest.param(
            ["analyze", "--include", "invalid"],
            INPUT_RESPONSE.source_list[0],
            False,
            2,
            id="invalid include",
        ),
        pytest.param(
            ["analyze", "--include", "invalid", "."],
            INPUT_RESPONSE.source_list[0],
            False,
            2,
            id="invalid include with path",
        ),
        pytest.param(
            ["analyze", "--swc-blacklist", "SWC-110"],
            INPUT_RESPONSE.source_list[0],
            False,
            0,
            id="blacklist 110",
        ),
        pytest.param(
            ["analyze", "--min-severity", "high"],
            INPUT_RESPONSE.source_list[0],
            False,
            0,
            id="high sev filter",
        ),
    ),
)
def test_parameters(tmp_path, params, value, contained, retval):
    setup_truffle_project(tmp_path, compiled=True, switch_dir=True)
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, params, input="y\n")

        if contained:
            assert value in result.output
        else:
            assert value not in result.output

        assert result.exit_code == retval
