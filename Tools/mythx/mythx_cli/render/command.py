import logging
from pathlib import Path
from typing import List, Optional, Tuple

import click
import htmlmin
import jinja2
from mythx_models.response import (
    AnalysisInputResponse,
    AnalysisStatusResponse,
    DetectedIssuesResponse,
)
from pythx import Client

from mythx_cli.render.util import get_analysis_info
from mythx_cli.util import write_or_print

LOGGER = logging.getLogger("mythx-cli")
DEFAULT_HTML_TEMPLATE = Path(__file__).parent / "templates/default.html"
DEFAULT_MD_TEMPLATE = Path(__file__).parent / "templates/default.md"


@click.command()
@click.argument("target")
@click.option(
    "--template",
    "-t",
    "user_template",
    type=click.Path(exists=True),
    help="A custom report template",
    default=None,
)
@click.option("--aesthetic", is_flag=True, default=False, hidden=True)
@click.option(
    "--markdown", is_flag=True, default=False, help="Render the report as Markdown"
)
@click.option(
    "--min-severity",
    type=click.STRING,
    help="Ignore SWC IDs below the designated level",
    default=None,
)
@click.option(
    "--swc-blacklist",
    type=click.STRING,
    help="A comma-separated list of SWC IDs to ignore",
    default=None,
)
@click.option(
    "--swc-whitelist",
    type=click.STRING,
    help="A comma-separated list of SWC IDs to include",
    default=None,
)
@click.pass_obj
def render(
    ctx,
    target: str,
    user_template: str,
    aesthetic: bool,
    markdown: bool,
    min_severity: Optional[str],
    swc_blacklist: Optional[List[str]],
    swc_whitelist: Optional[List[str]],
) -> None:
    """Render an analysis job or group report as HTML.

    \f
    :param ctx: Click context holding group-level parameters
    :param target: Group or analysis ID to fetch the data for
    :param user_template: User-defined template string
    :param aesthetic: DO NOT TOUCH IF YOU'RE BORING
    :param markdown: Flag to render a markdown report
    :param min_severity: Ignore SWC IDs below the designated level
    :param swc_blacklist: A comma-separated list of SWC IDs to ignore
    :param swc_whitelist: A comma-separated list of SWC IDs to include
    """

    client: Client = ctx["client"]
    # normalize target
    target = target.lower()
    default_template = DEFAULT_MD_TEMPLATE if markdown else DEFAULT_HTML_TEMPLATE
    # enables user to include library templates in their own
    template_dirs = [default_template.parent]

    if user_template:
        LOGGER.debug(f"Received user-defined template at {user_template}")
        user_template = Path(user_template)
        template_name = user_template.name
        template_dirs.append(user_template.parent)
    else:
        LOGGER.debug(f"Using default template {default_template.name}")
        template_name = default_template.name

    env_kwargs = {
        "trim_blocks": True,
        "lstrip_blocks": True,
        "keep_trailing_newline": True,
    }
    if not markdown:
        env_kwargs = {
            "trim_blocks": True,
            "lstrip_blocks": True,
            "keep_trailing_newline": True,
        }
        if aesthetic:
            LOGGER.debug(f"Overwriting template to go A E S T H E T I C")
            template_name = "aesthetic.html"

    LOGGER.debug("Initializing Jinja environment")
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(template_dirs), **env_kwargs
    )
    template = env.get_template(template_name)

    issues_list: List[
        Tuple[
            AnalysisStatusResponse,
            DetectedIssuesResponse,
            Optional[AnalysisInputResponse],
        ]
    ] = []
    if len(target) == 24:
        LOGGER.debug(f"Identified group target {target}")
        list_resp = client.analysis_list(group_id=target)
        offset = 0

        LOGGER.debug(f"Fetching analyses in group {target}")
        while len(list_resp.analyses) < list_resp.total:
            offset += len(list_resp.analyses)
            list_resp.analyses.extend(
                client.analysis_list(group_id=target, offset=offset)
            )

        for analysis in list_resp.analyses:
            click.echo(
                "Fetching report for analysis {}".format(analysis.uuid), err=True
            )
            status, resp, inp = get_analysis_info(
                client=client,
                uuid=analysis.uuid,
                min_severity=min_severity,
                swc_blacklist=swc_blacklist,
                swc_whitelist=swc_whitelist,
            )
            issues_list.append((status, resp, inp))
    elif len(target) == 36:
        LOGGER.debug(f"Identified analysis target {target}")
        click.echo("Fetching report for analysis {}".format(target), err=True)
        status, resp, inp = get_analysis_info(
            client=client,
            uuid=target,
            min_severity=min_severity,
            swc_blacklist=swc_blacklist,
            swc_whitelist=swc_whitelist,
        )
        issues_list.append((status, resp, inp))
    else:
        LOGGER.debug(f"Could not identify target with length {len(target)}")
        raise click.UsageError(
            "Invalid target. Please provide a valid group or analysis job ID."
        )

    LOGGER.debug(f"Rendering template for {len(issues_list)} issues")
    rendered = template.render(issues_list=issues_list, target=target)
    if not markdown:
        LOGGER.debug(f"Minifying HTML report")
        rendered = htmlmin.minify(rendered, remove_comments=True)

    write_or_print(rendered, mode="w+")
