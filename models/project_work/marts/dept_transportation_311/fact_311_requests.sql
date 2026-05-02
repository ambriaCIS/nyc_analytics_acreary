{{ config(materialized='table') }}

with requests as (

    select *
    from {{ ref('stg_nyc_311_service_request_history') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['unique_key']) }} as request_sk,

        dt.time_sk,
        dl.location_sk,
        dsr.service_request_sk,

        r.created_date as open_dt,
        r.closed_date as closed_dt,

        timestamp_diff(r.closed_date, r.created_date, hour) as response_time,

        r.status

    from requests r

    left join {{ ref('dim_time') }} dt
        on date(r.created_date) = dt.date

    left join {{ ref('dim_location') }} dl
        on coalesce(r.borough, '') = coalesce(dl.borough, '')
        and coalesce(cast(r.zip_code as string), '') = coalesce(dl.zip_code, '')
        and coalesce(cast(r.community_board as string), '') = coalesce(dl.community_board, '')
        and coalesce(cast(r.latitude as string), '') = coalesce(cast(dl.latitude as string), '')
        and coalesce(cast(r.longitude as string), '') = coalesce(cast(dl.longitude as string), '')

    left join {{ ref('dim_service_request') }} dsr
        on coalesce(r.complaint_type, '') = coalesce(dsr.complaint_type, '')
        and coalesce(r.descriptor, '') = coalesce(dsr.descriptor, '')
        and coalesce(r.agency, '') = coalesce(dsr.agency, '')
        and coalesce(r.resolution_description, '') = coalesce(dsr.resolution_description, '')

)

select * from final