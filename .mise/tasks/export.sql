SET enable_progress_bar = true;
SET enable_progress_bar_print = true;
SET progress_bar_time = 100;
SET max_memory = '2GB';
SET threads = 4;
INSTALL sqlite;
LOAD sqlite;

COPY (
    select region,
           AvailabilityZone as availability_zone,
           InstanceType     as instance_type,
           SpotPrice::NUMERIC(10, 6) as spot_price,
           Timestamp::TIMESTAMP_S as timestamp
    from read_json(
        'spot_price_data/*/*.jsonl.gz',
        columns = {AvailabilityZone: 'VARCHAR', InstanceType: 'VARCHAR', SpotPrice: 'VARCHAR', Timestamp: 'VARCHAR'},
        hive_partitioning = true
    )
 ) TO 'all.parquet'  (
    FORMAT parquet
    , COMPRESSION zstd
);

COPY
(
    select *
    FROM 'all.parquet'
    ORDER BY region, availability_zone, instance_type, timestamp
)
to 'history.parquet' (
    FORMAT parquet
    , COMPRESSION zstd
    , COMPRESSION_LEVEL 9
    , PRESERVE_ORDER true
    , PER_THREAD_OUTPUT false
    , OVERWRITE
    , PARQUET_VERSION v2
);

COPY
(
    select *
    FROM 'all.parquet'
    WHERE timestamp >= (select max(timestamp) from 'all.parquet') - INTERVAL 90 DAY
    ORDER BY region, availability_zone, instance_type, timestamp
)
to 'last-90-days.parquet' (
FORMAT parquet
    , COMPRESSION zstd
    , COMPRESSION_LEVEL 9
    , PRESERVE_ORDER true
    , PER_THREAD_OUTPUT false
    , OVERWRITE
    , PARQUET_VERSION v2
);

SELECT pg_size_pretty(sum(total_compressed_size)::bigint) as size,
    (SELECT count(*) FROM read_parquet('history.parquet')) as rows,
    (SELECT min(timestamp) FROM read_parquet('history.parquet')) as min_date,
    (SELECT max(timestamp) FROM read_parquet('history.parquet')) as max_date
FROM parquet_metadata('history.parquet');

SELECT pg_size_pretty(sum(total_compressed_size)::bigint) as size,
    (SELECT count(*) FROM read_parquet('last-90-days.parquet')) as rows,
    (SELECT min(timestamp) FROM read_parquet('last-90-days.parquet')) as min_date,
    (SELECT max(timestamp) FROM read_parquet('last-90-days.parquet')) as max_date
FROM parquet_metadata('last-90-days.parquet');

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