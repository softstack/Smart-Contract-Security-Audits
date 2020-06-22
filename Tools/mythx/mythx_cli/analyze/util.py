"""This module contains helpers for generating MythX analysis payloads."""

import logging
from enum import Enum
from glob import glob
from os.path import abspath, commonpath
from pathlib import Path
from typing import Dict, List, Tuple, Union

import click

LOGGER = logging.getLogger("mythx-cli")


class ScenarioMode(Enum):
    SOLIDITY_FILE = 1
    SOLIDITY_DIR = 2
    TRUFFLE = 3


def detect_truffle_files(
    path: Path, project_base: str = "build/contracts/*.json"
) -> bool:
    """Detect Truffle projects in paths.

    This function detects whether a Truffle project can be found
    in the given project base path.

    :param path: The path prefix to look in (e.g. the CLI target)
    :param project_base: The truffle-specific path suffix
    :return: Boolean indicating whether path contains a truffle project
    """
    return (path / "truffle-config.js").exists() or (path / "truffle.js").exists()


def determine_analysis_targets(
    target: str, forced_scenario: str
) -> List[Tuple[ScenarioMode, Union[Path, str]]]:
    """Determine the scenario for an analysis target.

    This function will, based on a list of targets or lack thereof, return a list
    of two-tuples, each containing the determined analysis scenario and the target.
    In case no initial target is given, the current working directory is used as a
    replacement.

    It is also possible to force evaluation of a given target (or the cwd) by
    passing the scenario name ("solidity" or "truffle") to the :code:`forced_scenario`
    parameter.

    :param target: The initial target to determine the scenario for
    :param forced_scenario: A string to manually override scenario detection
    :return: A list of tuples containing detected scenario and target
    """
    mode_list = []
    if not target:
        cwd = Path.cwd()
        if detect_truffle_files(cwd) or forced_scenario == "truffle":
            LOGGER.debug(f"Identified directory as truffle project")
            mode_list.append((ScenarioMode.TRUFFLE, cwd))  # TRUFFLE DIR
        elif list(glob("*.sol")) or forced_scenario == "solidity":
            LOGGER.debug(f"Identified directory with Solidity files")
            mode_list.append((ScenarioMode.SOLIDITY_DIR, cwd))  # SOLIDITY DIR
        else:
            raise click.exceptions.UsageError(
                "No argument given and unable to detect Truffle project or Solidity files"
            )
    else:
        for target_elem in target:
            element = Path(target_elem.split(":")[0])
            if (
                element.is_file() and element.suffix == ".sol"
            ) or forced_scenario == "solidity":
                LOGGER.debug(f"Identified target {str(element)} as solidity file")
                # pass target_elem here to catch the optional path:Contract syntax
                mode_list.append((ScenarioMode.SOLIDITY_FILE, target_elem))
            elif element.is_dir():
                LOGGER.debug(f"Identified target {str(element)} as directory")
                if (
                    detect_truffle_files(Path(target_elem))
                    or forced_scenario == "truffle"
                ):
                    LOGGER.debug(
                        f"Identified {str(element)} directory as truffle project"
                    )
                    mode_list.append((ScenarioMode.TRUFFLE, element))
                else:
                    # implicit: forced_scenario == "solidity"
                    LOGGER.debug(f"Identified {str(element)} as Solidity directory")
                    mode_list.append((ScenarioMode.SOLIDITY_DIR, element))
            else:
                raise click.exceptions.UsageError(
                    f"Could not interpret argument {target_elem} as bytecode, Solidity file, or Truffle project"
                )
    return mode_list


def delete_absolute_prefix(path: str, prefix: str):
    """Delete a prefix of an absolute path.

    If the path is not absolute yet, it will be expanded.

    :param path: Path string to delete the prefix from
    :param prefix: Prefix to remove
    :return: The trimmed path
    """
    absolute = Path(path).absolute()
    return str(absolute).replace(prefix, "")


def sanitize_paths(job: Dict) -> Dict:
    """Remove the common prefix from paths.

    This method takes a job payload, iterates through all paths, and
    removes all their common prefixes. This is an effort to only submit
    information on a need-to-know basis to MythX. Unless it's to distinguish
    between files, the API does not need to know the absolute path of a file.
    This may even leak user information and should be removed.

    If a common prefix cannot be found (e.g. if there is just one element in
    the source list), the relative path from the current working directory
    will be returned.

    This concerns the following fields:
    - sources
    - AST absolute path
    - legacy AST absolute path
    - source list
    - main source

    :param job: The payload to sanitize
    :return: The sanitized job
    """

    source_list = job.get("source_list")
    if not source_list:
        # triggers on None and empty list
        # if no source list is given, we are analyzing bytecode only
        LOGGER.debug("Job does not contain source list - skipping sanitization")
        return job

    LOGGER.debug("Converting source list items to absolute paths for trimming")
    source_list = [abspath(s) for s in source_list]
    if len(source_list) > 1:
        # get common path prefix and remove it
        LOGGER.debug("More than one source list item detected - trimming common prefix")
        prefix = commonpath(source_list) + "/"
    else:
        # fallback: replace with CWD and get common prefix
        LOGGER.debug("One source list item detected - trimming by CWD prefix")
        prefix = commonpath(source_list + [str(Path.cwd())]) + "/"

    LOGGER.debug(f"Trimming {prefix} from source list: {', '.join(source_list)}")
    sanitized_source_list = [delete_absolute_prefix(s, prefix) for s in source_list]
    job["source_list"] = sanitized_source_list
    LOGGER.debug(f"Trimmed source list: {', '.join(sanitized_source_list)}")
    if job.get("main_source") is not None:
        LOGGER.debug(f"Trimming main source path {job['main_source']}")
        job["main_source"] = delete_absolute_prefix(job["main_source"], prefix)
        LOGGER.debug(f"Trimmed main source path {job['main_source']}")
    for name in list(job.get("sources", {})):
        data = job["sources"].pop(name)
        # sanitize AST data in compiler output
        for ast_key in ("ast", "legacyAST"):
            LOGGER.debug(f"Sanitizing AST key '{ast_key}'")
            if not (data.get(ast_key) and data[ast_key].get("absolutePath")):
                LOGGER.debug(
                    f"Skipping sanitization: {ast_key} -> absolutePath not defined"
                )
                continue
            sanitized_absolute = delete_absolute_prefix(
                data[ast_key]["absolutePath"], prefix
            )
            LOGGER.debug(
                f"Setting sanitized {ast_key} -> absolutePath to {sanitized_absolute}"
            )
            data[ast_key]["absolutePath"] = sanitized_absolute

        # replace source key names
        sanitized_source_name = delete_absolute_prefix(name, prefix)
        LOGGER.debug(f"Setting sanitized source name {sanitized_source_name}")
        job["sources"][sanitized_source_name] = data

    return job


def is_valid_job(job) -> bool:
    """Detect interface contracts.

    This utility function is used to detect interface contracts in solc and Truffle
    artifacts. This is done by checking whether any bytecode or source maps are to be
    found in the speficied job. This check is performed after the payload has been
    assembled to cover Truffle and Solidity analysis jobs.

    :param job: The payload to perform the check on
    :return: True if the submitted job is for an interface, False otherwise
    """

    filter_values = ("", "0x", None)
    valid = True
    if len(job.keys()) == 1 and job.get("bytecode") not in filter_values:
        LOGGER.debug("Skipping validation for bytecode-only analysis")
    elif job.get("bytecode") in filter_values:
        LOGGER.debug(f"Invalid job because bytecode is {job.get('bytecode')}")
        valid = False
    elif job.get("source_map") in filter_values:
        LOGGER.debug(f"Invalid job because source map is {job.get('source_map')}")
        valid = False
    elif job.get("deployed_source_map") in filter_values:
        LOGGER.debug(
            f"Invalid job because deployed source map is {job.get('deployed_source_map')}"
        )
        valid = False
    elif job.get("deployed_bytecode") in filter_values:
        LOGGER.debug(
            f"Invalid job because deployed bytecode is {job.get('deployed_bytecode')}"
        )
        valid = False
    elif not job.get("contract_name"):
        LOGGER.debug(f"Invalid job because contract name is {job.get('contract_name')}")
        valid = False

    if not valid:
        # notify user
        click.echo(
            "Skipping submission for contract {} because no bytecode was produced.".format(
                job.get("contract_name")
            )
        )

    return valid
