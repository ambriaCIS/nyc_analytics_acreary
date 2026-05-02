{{ config(materialized='table') }}

with service_requests as (

    select distinct
        complaint_type,
        descriptor,
        agency,
        resolution_description
    from {{ ref('stg_nyc_311_service_request_history') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'complaint_type',
            'descriptor',
            'agency',
            'resolution_description'
        ]) }} as service_request_sk,

        complaint_type,
        descriptor,
        agency,
        resolution_description

    from service_requests

)

select * from final