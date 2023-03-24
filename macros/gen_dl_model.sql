{% macro gen_dl_model(source_name, source_relation) %}
{% set source = (graph.sources.values() | selectattr('source_name', 'equalto', source_name) |selectattr('name', 'equalto', source_relation) | list).pop() %}
{% set source_relation_meta = source['meta'] %}
{% set target_model_attrs = source_relation_meta['target'] %}
{% set target_model_name -%}
    {%- if target_model_attrs['name'] is defined -%}
        {{ target_model_attrs['name'] }}
    {%- else -%}
        {{ 'target_' ~ source_name ~ '__' ~ source_relation }}
    {%- endif -%}
{%- endset %}
{% set target_model_tags = target_model_attrs['tags'] %}
{% set target_load_strategy = target_model_attrs['load-strategy'] %}
{% set target_include_default_tests = target_model_attrs['include-default-tests'] %}
{% set columns = source['columns'].values() %}
{% set module_tag = '\n#codegenmodule' %}
{% set base_model_name = 'base_' ~ source_name ~ '__' ~ source_relation %}
{% set snapshot_name = source_name ~ '__' ~ source_relation ~ '_snapshot' %}
{% set module_meta = module_tag ~ ' {"type": "base", "filename": "' ~ base_model_name ~ '.sql"}\n'   %}
{{ print(module_meta) }}

{% set base_model_sql %}

{{'{{'}} config(materialized='view') {{'}}'}}


select 
    {% for column in columns %}
        {%- set transformed_value -%}
            {%- if column.meta['value-extract-sql'] is defined -%}
                {{ column.meta['value-extract-sql'] | replace("<columnname>", column.name) }}
            {%- elif column.meta['value-extract-macro'] is defined -%}
                {{'{{ '}}{{ column.meta['value-extract-macro'] | replace("<columnname>", "'" ~ column.name ~ "'") }}{{' }}'}}
            {%- else -%}
                {{ column.name }}
            {%- endif -%}
        {%- endset -%}

        {%- if column.meta is defined and column.meta.target is defined and column.meta.target['data-type'] is defined -%}
            {%- set cast_type = column.meta.target['data-type'] -%}
        {%- endif %}

        {%- if column.meta is defined and column.meta.target is defined and column.meta.target['name'] is defined -%}
            {%- set alias = column.meta.target['name'] -%}
        {%- else -%}
            {%- set alias = column.name -%}
        {%- endif %}

        {%- set casted_value -%}
            {%- if cast_type is defined -%}
                {{ 'cast(' ~ transformed_value ~ ' as ' ~ cast_type ~ ')'}}
            {%- else -%}
                {{ transformed_value }}
            {%- endif -%}
        {%- endset -%}
        {{ casted_value ~ ' as ' ~ alias }},
    {% endfor -%}

{%- if target_load_strategy == 'scd2' -%}
    dbt_scd_id,
    dbt_updated_at,
    dbt_valid_from,
    dbt_valid_to
from {{'{{'}}  ref('{{ snapshot_name }}')  {{'}}'}}
{%- else -%}
from {{'{{'}}  source('{{ source_name }}', '{{ source_relation }}')  {{'}}'}}
{%- endif -%}


{%- endset %}
{{ print(base_model_sql) }}

{%- if target_load_strategy == 'scd2' -%}
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

select *
from {{'{{'}}  source('{{ source_name }}', '{{ source_relation }}')  {{'}}'}}


{{'{% endsnapshot %}'}}

{%- endset %}

{{ print(snapshot_sql) }}
{%- endif -%}

{% set module_meta = module_tag ~ ' {"type": "stg", "filename": "' ~ target_model_name ~ '.sql"}\n'   %}
{{ print(module_meta) }}

{%- set mart_sql -%}
select *
from {{'{{'}} ref('{{ base_model_name }}') {{'}}'}}
{%- endset %}

{{ print(mart_sql) }}


{% set module_meta = module_tag ~ ' {"type": "config", "filename": "' ~ target_model_name ~ '.yml"}\n'   %}
{{ print(module_meta) }}

{%- set target_model_config -%}
version: 2

models:
  - name: {{ target_model_name }}
{%- if target_model_tags is defined %}
    tags: {{ target_model_tags }}
{%- endif %}
    tests:
{%- if target_include_default_tests %}
      - scd2_nonoverlappingrecords:
          key_column_name: {{ source['meta']['key-column'] }}
{%- endif %}
    columns:
{%- for column in columns -%}
    {%- if column.meta is defined and column.meta.target is defined and column.meta.target.tests is defined -%}

    {%- if column.meta is defined and column.meta.target is defined and column.meta.target.name is defined -%}
        {%- set column_name = column.meta.target.name -%}
    {%- else -%}
        {%- set column_name = column.name -%}
    {% endif %} 
      - name: {{ column_name }}
        tests:
        {%- for test in column.meta.target.tests %}
          - {{ test }}
        {%- endfor -%}        
    {%- endif -%}
{% endfor -%}
{%- endset %}

{{ print(target_model_config) }}

{% endmacro %}