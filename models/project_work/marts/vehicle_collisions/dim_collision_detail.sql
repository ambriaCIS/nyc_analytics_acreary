{{ config(materialized='table') }}

WITH collision_details AS (
    SELECT DISTINCT
        coalesce(contributing_factor_vehicle_1, 'UNKNOWN') AS contributing_factor_vehicle_1,
        coalesce(contributing_factor_vehicle_2, 'UNKNOWN') AS contributing_factor_vehicle_2,
        coalesce(vehicle_type_code1, 'UNKNOWN') AS vehicle_type_code1,
        coalesce(vehicle_type_code2, 'UNKNOWN') AS vehicle_type_code2
    FROM {{ ref('stg_nyc_service_mvcollision') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'contributing_factor_vehicle_1',
        'contributing_factor_vehicle_2',
        'vehicle_type_code1',
        'vehicle_type_code2'
    ]) }} AS collision_detail_sk,

    contributing_factor_vehicle_1,
    contributing_factor_vehicle_2,
    vehicle_type_code1,
    vehicle_type_code2

FROM collision_details