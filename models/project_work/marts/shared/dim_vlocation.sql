{{ config(materialized='table') }}

with locations as (

    -- 311 service requests (structured location data)
    select distinct
        borough,
        cast(zip_code as string) as zip_code,
        cast(community_board as string) as community_board,
        cast(latitude as numeric) as latitude,
        cast(longitude as numeric) as longitude
    from {{ ref('stg_nyc_311_service_request_history') }}

    union distinct

    -- Motor vehicle collisions (less structured location data)
    select distinct
        borough,

        -- zip_code may exist inconsistently → protect it
        cast(zip_code as string) as zip_code,

        -- collisions often don’t reliably have community_board
        cast(null as string) as community_board,

        cast(latitude as numeric) as latitude,
        cast(longitude as numeric) as longitude
    from {{ ref('stg_motor_vehicle_collisions') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'borough',
            'coalesce(zip_code, "unknown")',
            'coalesce(community_board, "unknown")',
            'latitude',
            'longitude'
        ]) }} as location_sk,

        borough,
        zip_code,
        community_board,
        latitude,
        longitude

    from locations

)

select * from final