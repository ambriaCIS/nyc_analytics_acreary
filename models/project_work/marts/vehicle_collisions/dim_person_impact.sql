{{ config(materialized='table') }}

with impact as (

    select distinct
        case
            when number_of_persons_killed > 0 then 'Fatal'
            when number_of_persons_injured > 0 then 'Injury'
            else 'No Injury'
        end as severity_level,

        case
            when number_of_persons_killed > 0 then 'At least one person was killed'
            when number_of_persons_injured > 0 then 'At least one person was injured'
            else 'No reported injuries or fatalities'
        end as description

    from {{ ref('stg_nyc_service_mvcollision') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['severity_level', 'description']) }} as person_impact_sk,
        severity_level,
        description
    from impact

)

select * from final