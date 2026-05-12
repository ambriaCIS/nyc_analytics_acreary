{{ config(materialized='table') }}

WITH stg_311 AS (
    SELECT * FROM {{ ref('stg_nyc_311_service_request_history') }}
),

dim_time AS (
    SELECT * FROM {{ ref('dim_time') }}
),

dim_location AS (
    SELECT * FROM {{ ref('dim_vlocation') }}
),

dim_service AS (
    SELECT * FROM {{ ref('dim_service_request') }}
)

SELECT
    -- Fact Table Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['s.unique_key']) }} AS fact_311_sk,

    -- Foreign Keys to Dimensions
    t.time_sk,
    l.location_sk,
    srv.service_request_sk,

    -- Degenerate Dimensions
    s.unique_key,
    s.status,
    s.latitude,
    s.longitude,

    -- Fact Metrics
    1 AS request_count

FROM stg_311 s

LEFT JOIN dim_time t 
    ON DATE(s.created_date) = t.date

LEFT JOIN dim_location l 
    ON coalesce(s.borough, 'UNKNOWN') = coalesce(l.borough, 'UNKNOWN') 
    AND coalesce(s.zip_code, 'UNKNOWN') = coalesce(l.zip_code, 'UNKNOWN')

LEFT JOIN dim_service srv 
    ON coalesce(s.complaint_type, 'UNKNOWN') = coalesce(srv.complaint_type, 'UNKNOWN')
    AND coalesce(s.agency, 'UNKNOWN') = coalesce(srv.agency, 'UNKNOWN')
    AND coalesce(s.agency_name, 'UNKNOWN') = coalesce(srv.agency_name, 'UNKNOWN')