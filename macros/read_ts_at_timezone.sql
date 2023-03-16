{% macro  read_ts_at_timezone(column_name, timezone) %}
    TIMESTAMP({{ column_name }}, '{{ timezone }}')
{% endmacro %}