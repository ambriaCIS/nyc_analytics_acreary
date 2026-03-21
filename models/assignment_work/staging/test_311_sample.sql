-- Quick test to verify source connection works
 SELECT
     unique_key,
     created_date,
     complaint_type,
     borough
 FROM {{ source('raw', 'nyc_hw3_raw_data_source_dot_service_requests_history') }}
 LIMIT 10