{% extends "layout.md" %}

{% block heading %}
# MythX Report for {{ target }} and Dependencies
{% endblock %}

{% block header %}
##  Report for {{ input.main_source }}
[View on MythX Dashboard](https://dashboard.mythx.io/#/console/analyses/{{ report.uuid }})

{% endblock %}

{% block status %}
| High | Medium | Low | Unknown |
|------|--------|-----|---------|
| {{ "%-4s" | format(status.vulnerability_statistics.high,) }} | {{ "%-6s" | format(status.vulnerability_statistics.medium,) }} | {{ "%-3s" | format(status.vulnerability_statistics.low,) }} | {{ "%-7s" | format(status.vulnerability_statistics.none,) }} |

{% endblock %}

{% block report %}
{% for issue in report %}
{% for loc in issue.locations %}
{% if loc.source_format == "text" %}
{% set source_file=loc.source_list[loc.source_map.components[0].file_id] %}
- **Issue:** {{ issue.swc_id }} - {{ issue.swc_title }}
- **Severity:** {{ issue.severity|title }}
- **Description:** {{ issue.description_long }}
- **Location:** {{ source_file }}
{% if loop.index0 < issue.decoded_locations|length and issue.decoded_locations[loop.index0].start_line %}
{% set location=issue.decoded_locations[loop.index0] %}
- **Line:** {{ location.start_line }}
- **Column:** {{ location.start_column }}
{% set source_data=input.sources[source_file]["source"].split("\n") %}

```
{{ source_data[location.start_line-2]}}
{{ source_data[location.start_line-1]}}
{{ source_data[location.start_line]}}
```


{% endif %}
{% endif %}
{% endfor %}
{% endfor %}
{% endblock %}

{% block postamble %}
----------
Made with ♥ by [MythX CLI](https://github.com/dmuhs/mythx-cli)
{% endblock %}
