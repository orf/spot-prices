INSTALL sqlite;
LOAD sqlite;

copy
(
    select region,
       AvailabilityZone as availability_zone,
       InstanceType     as instance_type,
       SpotPrice::NUMERIC(10, 6) as spot_price, Timestamp ::TIMESTAMPTZ as timestamp
    from read_json_auto(
        'spot_price_data/*/*.jsonl.gz', hive_partitioning = true
    )
    ORDER BY region, availability_zone, instance_type, timestamp
)
to 'history.parquet' (COMPRESSION 'ZSTD');


ATTACH 'history.sqlite' AS sqlite_db (TYPE SQLITE);
drop table if exists sqlite_db.spot_prices;
create table sqlite_db.spot_prices AS (
    select
        region,
        availability_zone,
        instance_type,
        spot_price::REAL as spot_price,
        epoch(timestamp) as timestamp
    from 'history.parquet'
);