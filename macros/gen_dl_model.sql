{% macro gen_dl_model(source_name, source_relation) %}
{% set source = (graph.sources.values() | selectattr('source_name', 'equalto', source_name) |selectattr('name', 'equalto', source_relation) | list).pop() %}
{% set columns = source['columns'].values() %}
{% set module_tag = '\n#codegenmodule' %}
{% set base_model_name = 'base_' ~ source_name ~ '__' ~ source_relation %}
{% set snapshot_name = source_name ~ '__' ~ source_relation ~ '_snapshot' %}
{% set target_name = 'target_' ~ source_name ~ '__' ~ source_relation %}

{% set module_meta = module_tag ~ ' {"type": "base", "filename": "' ~ base_model_name ~ '.sql"}\n'   %}
{{ print(module_meta) }}

{% set base_model_sql %}

{{'{{'}} config(materialized='view') {{'}}'}}


select 
    {% for column in columns %}
        {%- set transformed_value -%}
            {%- if column.meta['value-extract-sql'] is defined -%}
                {{ column.meta['value-extract-sql'] }}
            {%- else -%}
                {{ column.name }}
            {%- endif -%}
        {%- endset -%}

        {%- set casted_value -%}
            {%- if column.meta['target-type'] is defined -%}
                {{ 'cast(' ~ transformed_value ~ ' as ' ~ column.meta['target-type'] ~ ')'}}
            {%- else -%}
                {{ transformed_value }}
            {%- endif -%}
        {%- endset -%}
        {{ casted_value ~ ' as ' ~ column.name }}{{ "," if not loop.last }}
    {% endfor %}
from {{'{{'}}  source('{{ source_name }}', '{{ source_relation }}')  {{'}}'}}

{%- endset %}
{{ print(base_model_sql) }}

{% set module_meta = module_tag ~ ' {"type": "snapshot", "filename": "' ~ snapshot_name ~ '.sql"}\n'   %}
{{ print(module_meta) }}

{%- set snapshot_sql -%}
{{'{%'}} snapshot {{ snapshot_name}} {{'%}'}}

{{'{{'}}
    config(
      unique_key='{{ source['meta']['key-column'] }}',
      target_schema=target.schema,
      strategy='timestamp',
      updated_at='{{ source['meta']['timestamp-column'] }}',
    )
{{'}}'}}
{{'{% endsnapshot %}'}}

select *
from {{'{{'}} ref('{{ base_model_name }}') {{'}}'}}

{%- endset %}

{{ print(snapshot_sql) }}

{% set module_meta = module_tag ~ ' {"type": "stg", "filename": "' ~ target_name ~ '.sql"}\n'   %}
{{ print(module_meta) }}

{%- set mart_sql -%}
select *
from {{'{{'}} ref('{{ snapshot_name }}') {{'}}'}}
{%- endset %}

{{ print(mart_sql) }}

{% endmacro %}
