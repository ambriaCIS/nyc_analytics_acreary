-- Clean and standardize Motor Vehicle Collisions Data
-- One row per collision event

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_motor_vehicle_collisions') }}
),

cleaned AS (
    SELECT
        * EXCEPT (
            collision_id,
            crash_date,
            crash_time,
            borough,
            zip_code,
            latitude,
            longitude,
            number_of_persons_injured,
            number_of_persons_killed
        ),

        -- Identifiers
        CAST(collision_id AS STRING) AS collision_id,

        -- Date/Time
        CAST(crash_date AS TIMESTAMP) AS crash_date,
        CAST(crash_time AS STRING) AS crash_time,

        -- Location - Standardize borough
        CASE
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Location - Clean zip code
        CASE
            WHEN UPPER(TRIM(CAST(zip_code AS STRING))) IN ('N/A', 'NA', 'ANONYMOUS') THEN NULL
            WHEN LENGTH(CAST(zip_code AS STRING)) = 5 THEN CAST(zip_code AS STRING)
            WHEN LENGTH(CAST(zip_code AS STRING)) = 9 THEN SUBSTR(CAST(zip_code AS STRING), 1, 5)
            WHEN LENGTH(CAST(zip_code AS STRING)) = 10 AND REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}-\d{4}') THEN SUBSTR(CAST(zip_code AS STRING), 1, 5)
            ELSE NULL
        END AS zip_code,

        -- Geolocation
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- Facts / Metrics
        CAST(number_of_persons_injured AS INT64) AS number_of_persons_injured,
        CAST(number_of_persons_killed AS INT64) AS number_of_persons_killed,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters to drop garbage records
    WHERE collision_id IS NOT NULL
      AND crash_date IS NOT NULL

    -- Deduplication
    QUALIFY ROW_NUMBER() OVER (PARTITION BY collision_id ORDER BY crash_date DESC) = 1
)

SELECT * FROM cleaned