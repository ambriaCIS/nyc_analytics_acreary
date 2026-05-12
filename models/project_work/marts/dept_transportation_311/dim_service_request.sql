{{ config(materialized='table') }}

WITH service_requests AS (
    SELECT DISTINCT
        coalesce(complaint_type, 'UNKNOWN') AS complaint_type,
        coalesce(agency, 'UNKNOWN') AS agency,
        coalesce(agency_name, 'UNKNOWN') AS agency_name
    FROM {{ ref('stg_nyc_311_service_request_history') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'complaint_type',
        'agency',
        'agency_name'
    ]) }} AS service_request_sk,

    complaint_type,
    agency,
    agency_name

FROM service_requests