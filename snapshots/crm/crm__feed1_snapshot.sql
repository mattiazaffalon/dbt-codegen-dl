
{% snapshot crm__feed1_snapshot %}

{{
    config(
      unique_key='key',
      target_schema=target.schema,
      strategy='timestamp',
      updated_at='last_upd',
    )
}}

select *
from {{  source('crm', 'feed1')  }}


{% endsnapshot %}


