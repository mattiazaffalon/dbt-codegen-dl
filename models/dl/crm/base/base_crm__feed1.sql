


{{ config(materialized='view') }}


select 
    key as key,
    cast(REPLACE(numeric_column, ',', '.') as numeric) as alias_numeric_column,
    cast({{ read_ts_at_timezone('ts_column', 'UTC+1') }} as timestamp) as ts_column,
    cast(last_upd as datetime) as last_upd,
    dbt_scd_id,
    dbt_updated_at,
    dbt_valid_from,
    dbt_valid_to
from {{  ref('crm__feed1_snapshot')  }}


