
{% snapshot crm__feed1_snapshot %}

{{
    config(
      unique_key='key',
      target_schema=target.schema,
      strategy='timestamp',
      updated_at='last_upd',
    )
}}
{% endsnapshot %}

select *
from {{ ref('base_crm__feed1') }}


