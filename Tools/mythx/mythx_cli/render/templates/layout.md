{% block heading scoped %}{% endblock %}
{% block preamble scoped %}{% endblock %}
{% for status, report, input in issues_list %}
{% block header scoped %}{% endblock %}
{% if report %}
{% block status scoped %}{% endblock %}
{% block report scoped %}{% endblock %}
{% else %}
{% block no_issues_name scoped %}
*No issues have been found.*

{% endblock %}
{% endif %}

{% endfor %}
{% block postamble scoped %}{% endblock %}
