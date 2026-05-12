{{ config(materialized='table') }}

WITH locations AS (
    SELECT DISTINCT
        coalesce(borough, 'UNKNOWN') AS borough,
        coalesce(zip_code, 'UNKNOWN') AS zip_code
    FROM {{ ref('stg_nyc_311_service_request_history') }}

    UNION DISTINCT

    SELECT DISTINCT
        coalesce(borough, 'UNKNOWN') AS borough,
        coalesce(zip_code, 'UNKNOWN') AS zip_code
    FROM {{ ref('stg_nyc_service_mvcollision') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['borough','zip_code']) }} AS location_sk,
    borough,
    zip_code
FROM locations