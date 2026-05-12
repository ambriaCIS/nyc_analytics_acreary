{{ config(materialized='table') }}

WITH collisions AS (
    SELECT * FROM {{ ref('stg_nyc_service_mvcollision') }}
),

dim_time AS (
    SELECT * FROM {{ ref('dim_time') }}
),

dim_location AS (
    SELECT * FROM {{ ref('dim_vlocation') }}
),

dim_detail AS (
    SELECT * FROM {{ ref('dim_collision_detail') }}
),

dim_impact AS (
    SELECT * FROM {{ ref('dim_person_impact') }}
)

SELECT
    -- Fact Table Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['c.collision_id']) }} AS fact_collision_sk,

    -- Foreign Keys to Dimensions
    t.time_sk,
    l.location_sk,
    d.collision_detail_sk,
    i.person_impact_sk,

    -- Degenerate Dimensions
    c.collision_id,
    c.crash_time,
    
    -- Fact Metrics
    c.number_of_persons_injured AS persons_injured,
    c.number_of_persons_killed AS persons_killed

FROM collisions c

LEFT JOIN dim_time t
    ON DATE(c.crash_date) = t.date

LEFT JOIN dim_location l
    ON coalesce(c.borough, 'UNKNOWN') = coalesce(l.borough, 'UNKNOWN')
    AND coalesce(c.zip_code, 'UNKNOWN') = coalesce(l.zip_code, 'UNKNOWN')

LEFT JOIN dim_detail d
    ON coalesce(c.contributing_factor_vehicle_1, 'UNKNOWN') = coalesce(d.contributing_factor_vehicle_1, 'UNKNOWN')
    AND coalesce(c.contributing_factor_vehicle_2, 'UNKNOWN') = coalesce(d.contributing_factor_vehicle_2, 'UNKNOWN')
    AND coalesce(c.vehicle_type_code1, 'UNKNOWN') = coalesce(d.vehicle_type_code1, 'UNKNOWN')
    AND coalesce(c.vehicle_type_code2, 'UNKNOWN') = coalesce(d.vehicle_type_code2, 'UNKNOWN')

LEFT JOIN dim_impact i
    ON CASE
        WHEN c.number_of_persons_killed > 0 THEN 'Fatal'
        WHEN c.number_of_persons_injured > 0 THEN 'Injury'
        ELSE 'No Injury'
    END = i.severity_level