{% test scd2_nonoverlappingrecords(model, key_column_name) %}

    SELECT
    c.*
    FROM 
    {{ model }} c INNER JOIN {{ model }} c1 ON (c.{{ key_column_name }} = c1.{{ key_column_name }} )
    WHERE
    c.dbt_scd_id <> c1.dbt_scd_id
    AND ((c.dbt_valid_from >= c1.dbt_valid_from
        AND COALESCE(c.dbt_valid_to, {{ upper_infinity_datetime() }}) <= COALESCE(c1.dbt_valid_to, {{ upper_infinity_datetime() }}))
        OR (c1.dbt_valid_from >= c.dbt_valid_from
        AND COALESCE(c1.dbt_valid_to, {{ upper_infinity_datetime() }}) <= COALESCE(c.dbt_valid_to, {{ upper_infinity_datetime() }})))

{% endtest %}