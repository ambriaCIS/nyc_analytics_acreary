-- One row per service request
-- dbt run --select stg_nyc_open_restaurant_apps
WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
), -- Easier to refer to the dbt reference to a long name table

cleaned AS (
    SELECT
        -- Get all columns from source, except ones we're transforming below
        * EXCEPT (
            objectid,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            business_address,
            bulding_number,
            street,
            borough,
            zip,
            latitude,
            longitude,
            time_of_submission,
            roadway_dimensions_length,
            roadway_dimensions_width,
            sidewalk_dimensions_length,
            sidewalk_dimensions_width,
            food_service_establishment,
            seating_interest_sidewalk,
            approved_for_sidewalk_seating,
            approved_for_roadway_seating,
            qualify_alcohol
        ),

        -- Identifier
        CAST(objectid AS STRING) AS restaurant_id,

        -- Business info
        TRIM(CAST(restaurant_name AS STRING)) AS restaurant_name,
        TRIM(CAST(legal_business_name AS STRING)) AS legal_business_name,
        TRIM(CAST(doing_business_as_dba AS STRING)) AS doing_business_as,

        -- Address info
        TRIM(CAST(business_address AS STRING)) AS business_address,
        CAST(bulding_number AS STRING) AS building_number,
        TRIM(CAST(street AS STRING)) AS street,

        -- Zip code cleaning
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10
                 AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}') THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip_code,

        -- Borough standardization
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Coordinates
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- Timestamp
        TIMESTAMP(time_of_submission) AS submitted_at,

        -- Program info
        CAST(food_service_establishment AS STRING) AS food_service_establishment,
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,
        CAST(approved_for_sidewalk_seating AS STRING) AS approved_sidewalk,
        CAST(approved_for_roadway_seating AS STRING) AS approved_roadway,
        CAST(qualify_alcohol AS STRING) AS alcohol,

        -- Dimensions
        CAST(roadway_dimensions_length AS FLOAT64) AS roadway_length,
        CAST(roadway_dimensions_width AS FLOAT64) AS roadway_width,
        CAST(sidewalk_dimensions_length AS FLOAT64) AS sidewalk_length,
        CAST(sidewalk_dimensions_width AS FLOAT64) AS sidewalk_width,

        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE objectid IS NOT NULL
      AND borough IS NOT NULL

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (PARTITION BY objectid ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM cleaned