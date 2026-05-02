{{ config(materialized='table') }}

with locations as (

    select distinct
        borough,
        cast(zip_code as string) as zip_code,
        cast(community_board as string) as community_board,
        cast(latitude as numeric) as latitude,
        cast(longitude as numeric) as longitude
    from {{ ref('stg_nyc_311_service_request_history') }}

    union distinct

    select distinct
        borough,
        cast(zip_code as string) as zip_code,
        cast(null as string) as community_board,
        cast(latitude as numeric) as latitude,
        cast(longitude as numeric) as longitude
    from {{ ref('stg_nyc_service_mvcollision') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'borough',
            'zip_code',
            'community_board',
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