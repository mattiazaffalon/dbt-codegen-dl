


{{ config(materialized='view') }}


select 
    key as key,
    cast(REPLACE(othercolumn, ',', '.') as numeric) as othercolumn,
    cast(last_upd as datetime) as last_upd
    
from {{  source('crm', 'feed1')  }}


