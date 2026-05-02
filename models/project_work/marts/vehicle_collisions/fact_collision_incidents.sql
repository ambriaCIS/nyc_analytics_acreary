{{ config(materialized='table') }}

with collisions as (

    select *
    from {{ ref('stg_nyc_service_mvcollision') }}

),

final as (

    select
        c.collision_id as collision_sk,

        dt.time_sk,
        dl.location_sk,
        dcd.collision_detail_sk,
        dpi.person_impact_sk,

        c.number_of_persons_injured as persons_injured,
        c.number_of_persons_killed as persons_killed,

        c.on_street_name,

        c.contributing_factor_vehicle_1 as contributing_factor

    from collisions c

    left join {{ ref('dim_time') }} dt
        on date(c.crash_date) = dt.date

    left join {{ ref('dim_location') }} dl
        on coalesce(c.borough, '') = coalesce(dl.borough, '')
        and coalesce(cast(c.zip_code as string), '') = coalesce(dl.zip_code, '')
        and dl.community_board is null
        and coalesce(cast(c.latitude as string), '') = coalesce(cast(dl.latitude as string), '')
        and coalesce(cast(c.longitude as string), '') = coalesce(cast(dl.longitude as string), '')

    left join {{ ref('dim_collision_detail') }} dcd
        on coalesce(c.contributing_factor_vehicle_1, '') = coalesce(dcd.contributing_factor_vehicle_1, '')
        and coalesce(c.contributing_factor_vehicle_2, '') = coalesce(dcd.contributing_factor_vehicle_2, '')
        and coalesce(c.vehicle_type_code1, '') = coalesce(dcd.vehicle_type_code1, '')
        and coalesce(c.vehicle_type_code2, '') = coalesce(dcd.vehicle_type_code2, '')
        and coalesce(c.number_of_persons_injured, 0) = coalesce(dcd.number_of_persons_injured, 0)
        and coalesce(c.number_of_persons_killed, 0) = coalesce(dcd.number_of_persons_killed, 0)

    left join {{ ref('dim_person_impact') }} dpi
        on case
            when c.number_of_persons_killed > 0 then 'Fatal'
            when c.number_of_persons_injured > 0 then 'Injury'
            else 'No Injury'
        end = dpi.severity_level

)

select * from final