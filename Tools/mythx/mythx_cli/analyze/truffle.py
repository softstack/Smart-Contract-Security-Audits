"""This module contains functions to generate payloads for Truffle projects."""

import json
import logging
import re
import sys
from glob import glob
from pathlib import Path
from typing import List, Set, Tuple, Union

import click

LOGGER = logging.getLogger("mythx-cli")


class TruffleJob:
    """A truffle job to be sent to the API.

    This object represents a collection of truffle artifacts that will
    be sent to the API. It aggregates artifacts and transforms them into
    API-conform payload dicts.
    """

    def __init__(self, target: Path):
        self.target = target
        self.payloads = []

    def find_truffle_artifacts(
        self
    ) -> Union[Tuple[List[str], List[str]], Tuple[None, None]]:
        """Look for a Truffle build folder and return all relevant JSON artifacts.

        This function will skip the Migrations.json file and return all other files
        under :code:`<project-dir>/build/contracts/`. If no files were found,
        :code:`None` is returned.

        :return: Files under :code:`<project-dir>/build/contracts/` or :code:`None`
        """

        output_pattern = self.target / "build" / "contracts" / "*.json"
        artifact_files = list(glob(str(output_pattern.absolute())))
        if not artifact_files:
            LOGGER.debug(f"No truffle artifacts found in pattern {output_pattern}")
            return None, None

        sources: Set[Tuple[int, str]] = set()
        for file in artifact_files:
            with open(file) as af:
                artifact = json.load(af)
                try:
                    ast = artifact.get("ast") or artifact.get("legacyAST")
                    idx = ast.get("src", "").split(":")[2]
                    sources.add((int(idx), artifact.get("sourcePath")))
                except (KeyError, IndexError) as e:
                    LOGGER.warning(f"Could not reconstruct artifact source list: {e}")
                    sys.exit(1)

        # infer source list from artifact collection
        source_list = [x[1] for x in sorted(list(sources), key=lambda x: x[0])]
        return artifact_files, source_list

    def generate_payloads(self):
        """Generate a MythX analysis request payload based on a truffle build
        artifact.

        This will send the following artifact entries to MythX for analysis:

        * :code:`contractName`
        * :code:`bytecode`
        * :code:`deployedBytecode`
        * :code:`sourceMap`
        * :code:`deployedSourceMap`
        * :code:`sourcePath`
        * :code:`source`
        * :code:`ast`
        * :code:`legacyAST`
        * the compiler version

        :return: The payload dictionary to be sent to MythX
        """

        artifact_files, source_list = self.find_truffle_artifacts()

        if not artifact_files:
            raise click.exceptions.UsageError(
                "Could not find any truffle artifacts. Did you run truffle compile?"
            )
        LOGGER.debug(f"Detected Truffle project with files:{', '.join(artifact_files)}")

        for file in artifact_files:
            with open(file) as af:
                artifact = json.load(af)
                LOGGER.debug(f"Loaded Truffle artifact with {len(artifact)} keys")

            self.payloads.append(
                {
                    "contract_name": artifact.get("contractName"),
                    "bytecode": self.patch_truffle_bytecode(artifact.get("bytecode"))
                    if artifact.get("bytecode") != "0x"
                    else None,
                    "deployed_bytecode": self.patch_truffle_bytecode(
                        artifact.get("deployedBytecode")
                    )
                    if artifact.get("deployedBytecode") != "0x"
                    else None,
                    "source_map": artifact.get("sourceMap")
                    if artifact.get("sourceMap")
                    else None,
                    "deployed_source_map": artifact.get("deployedSourceMap")
                    if artifact.get("deployedSourceMap")
                    else None,
                    "sources": {
                        artifact.get("sourcePath"): {
                            "source": artifact.get("source"),
                            "ast": artifact.get("ast"),
                            "legacyAST": artifact.get("legacyAST"),
                        }
                    },
                    "source_list": source_list,
                    "main_source": artifact.get("sourcePath"),
                    "solc_version": artifact["compiler"]["version"],
                }
            )

    @staticmethod
    def patch_truffle_bytecode(code: str) -> str:
        """Patch Truffle bytecode placeholders.

        This function patches placeholders in Truffle artifact files. These placeholders are meant
        to be replaced with deployed library/dependency addresses on deployment, but do not form
        valid EVM bytecode. To produce a valid payload, placeholders are replaced with the zero-address.

        :param code: The bytecode to patch
        :return: The patched bytecode with the zero-address filled in
        """
        return re.sub(re.compile(r"__\w{38}"), "0" * 40, code)
