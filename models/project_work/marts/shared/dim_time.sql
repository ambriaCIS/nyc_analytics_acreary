{{ config(materialized='table') }}

with dates as (

    select distinct
        date(created_date) as date
    from {{ ref('stg_nyc_311_service_request_history') }}

    union distinct

    select distinct
        date(crash_date) as date
    from {{ ref('stg_nyc_service_mvcollision') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['date']) }} as time_sk,
        date,
        extract(year from date) as year,
        extract(quarter from date) as quarter,
        extract(month from date) as month,
        format_date('%B', date) as month_name,
        extract(day from date) as day,
        format_date('%A', date) as weekday
    from dates
    where date is not null

)

select * from final