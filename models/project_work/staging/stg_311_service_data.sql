-- Clean and standardize 311 Service Data
-- One row per service request

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_311_service_data') }}
),

cleaned AS (
    SELECT
        * EXCEPT (
            unique_key,
            created_date,
            closed_date,
            agency,
            agency_name,
            complaint_type,
            status,
            incident_zip,
            borough,
            latitude,
            longitude
        ),

        -- Identifiers
        CAST(unique_key AS STRING) AS unique_key,

        -- Date/Time 
        CAST(created_date AS TIMESTAMP) AS created_date,
        CAST(closed_date AS TIMESTAMP) AS closed_date,

        -- Request details
        CAST(agency AS STRING) AS agency,
        CAST(agency_name AS STRING) AS agency_name,
        CAST(complaint_type AS STRING) AS complaint_type,
        UPPER(TRIM(CAST(status AS STRING))) AS status,

        -- Location - Clean zip code
        CASE
            WHEN UPPER(TRIM(CAST(incident_zip AS STRING))) IN ('N/A', 'NA', 'ANONYMOUS') THEN NULL
            WHEN LENGTH(CAST(incident_zip AS STRING)) = 5 THEN CAST(incident_zip AS STRING)
            WHEN LENGTH(CAST(incident_zip AS STRING)) = 9 THEN SUBSTR(CAST(incident_zip AS STRING), 1, 5)
            WHEN LENGTH(CAST(incident_zip AS STRING)) = 10 AND REGEXP_CONTAINS(CAST(incident_zip AS STRING), r'^\d{5}-\d{4}') THEN SUBSTR(CAST(incident_zip AS STRING), 1, 5)
            ELSE NULL
        END AS zip_code,

        -- Location - Standardize borough
        CASE
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Geolocation
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters to drop garbage records
    WHERE unique_key IS NOT NULL
      AND created_date IS NOT NULL

    -- Deduplication
    QUALIFY ROW_NUMBER() OVER (PARTITION BY unique_key ORDER BY created_date DESC) = 1
)

SELECT * FROM cleaned