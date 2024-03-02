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
