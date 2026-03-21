-- One row per service request

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
    SELECT
        -- Keep everything except fields we want to clean/transform
        * EXCEPT (
            id,
            restaurant_name,
            legal_business_name,
            doing_business_as,
            building_number,
            street,
            borough,
            zip,
            latitude,
            longitude
        ),

        -- Identifiers
        CAST(id AS STRING) AS restaurant_id,

        -- Business info
        TRIM(CAST(restaurant_name AS STRING)) AS restaurant_name,
        TRIM(CAST(legal_business_name AS STRING)) AS legal_business_name,
        TRIM(CAST(doing_business_as AS STRING)) AS doing_business_as,

        -- Address
        CAST(building_number AS STRING) AS building_number,
        TRIM(CAST(street AS STRING)) AS street,

        -- Clean zip code (updated to use `zip`)
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10
                AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
            THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip_code,

        -- Standardized borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Location
        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,

        -- Program details
        CAST(food_service_establishment AS STRING) AS food_service_establishment,
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,
        CAST(seating_interest_roadway AS STRING) AS seating_interest_roadway,
        CAST(alcohol AS STRING) AS alcohol,

        CAST(sidewalk_dimensions_length AS FLOAT64) AS sidewalk_length,
        CAST(sidewalk_dimensions_width AS FLOAT64) AS sidewalk_width,
        CAST(roadway_dimensions_length AS FLOAT64) AS roadway_length,
        CAST(roadway_dimensions_width AS FLOAT64) AS roadway_width,

        CAST(approved_for_sidewalk_seating AS STRING) AS approved_sidewalk,
        CAST(approved_for_roadway_seating AS STRING) AS approved_roadway,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE id IS NOT NULL
      AND borough IS NOT NULL

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) = 1
)

SELECT * FROM cleaned