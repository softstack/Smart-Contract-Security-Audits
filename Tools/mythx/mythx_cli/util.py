import logging
from typing import Any

import click

LOGGER = logging.getLogger("mythx-cli")


def update_context(
    context: dict, context_key: str, config: dict, config_key: str, default: Any = None
):
    """Update the click context based on a configuration dict.

    If the specified key is set in the configuration dict, it will
    be added/overwrite the respective other key in the click context.

    :param context: The click context dict to set/overwrite
    :param context_key: The key in the click context to overwrite
    :param config: The config to read additional data from
    :param config_key: The config key to overwrite with
    :param default: The default value to use if all lookups fail
    """

    context[context_key] = context.get(context_key) or config.get(config_key) or default


@click.pass_obj
def write_or_print(ctx, data: str, mode="a+") -> None:
    """Depending on the context, write the given content to stdout or a given
    file.

    :param ctx: Click context holding group-level parameters
    :param data: The data to print or write to a file
    :param mode: The mode to open the file in (if file output enabled)
    :return:
    """

    if not ctx["output"]:
        LOGGER.debug("Writing data to stdout")
        click.echo(data)
        return
    with open(ctx["output"], mode) as outfile:
        LOGGER.debug(f"Writing data to {ctx['output']}")
        outfile.write(data + "\n")
