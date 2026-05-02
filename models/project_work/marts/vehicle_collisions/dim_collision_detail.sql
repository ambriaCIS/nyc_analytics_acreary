{{ config(materialized='table') }}

with collision_details as (

    select distinct
        contributing_factor_vehicle_1,
        contributing_factor_vehicle_2,
        vehicle_type_code1,
        vehicle_type_code2,
        number_of_persons_injured,
        number_of_persons_killed
    from {{ ref('stg_nyc_service_mvcollision') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'contributing_factor_vehicle_1',
            'contributing_factor_vehicle_2',
            'vehicle_type_code1',
            'vehicle_type_code2',
            'number_of_persons_injured',
            'number_of_persons_killed'
        ]) }} as collision_detail_sk,

        contributing_factor_vehicle_1,
        contributing_factor_vehicle_2,
        vehicle_type_code1,
        vehicle_type_code2,
        number_of_persons_injured,
        number_of_persons_killed

    from collision_details

)

select * from final