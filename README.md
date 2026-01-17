# AWS Spot Prices

This repo contains historic and present AWS Spot prices for all publicly available regions.

Data is available in two formats:

1. Raw, gzip-compressed JSON inside the [spot_price_data](./spot_price_data) directory
2. Parquet files from the [latest release](https://github.com/orf/spot-prices/releases/tag/latest):
    - [`history.parquet`](https://github.com/orf/spot-prices/releases/download/latest/history.parquet) - Full history of all spot prices
    - [`last-90-days.parquet`](https://github.com/orf/spot-prices/releases/download/latest/last-90-days.parquet) - Last 90 days of spot prices (smaller file for quicker analysis)

## Schema

| Column            | Type         |
|-------------------|--------------|
| region            | VARCHAR      |
| availability_zone | VARCHAR      |
| instance_type     | VARCHAR      |
| spot_price        | DECIMAL(7,4) |
| timestamp         | TIMESTAMP_S  |

## Example: Query with DuckDB

**Note**: Download the file, don't query it directly from the URL.

```sql
SELECT *
FROM 'https://github.com/orf/spot-prices/releases/download/latest/history.parquet'
WHERE instance_type = 'c6i.2xlarge'
  AND region = 'eu-west-1'
ORDER BY timestamp DESC
    LIMIT 10;
```

| region    | availability_zone | instance_type | spot_price | timestamp           |
|-----------|-------------------|---------------|-----------:|---------------------|
| eu-west-1 | eu-west-1a        | c6i.2xlarge   |   0.220900 | 2026-01-16 22:31:31 |
| eu-west-1 | eu-west-1b        | c6i.2xlarge   |   0.236400 | 2026-01-16 21:17:26 |
| eu-west-1 | eu-west-1c        | c6i.2xlarge   |   0.226000 | 2026-01-16 19:46:39 |
| eu-west-1 | eu-west-1b        | c6i.2xlarge   |   0.236100 | 2026-01-16 15:16:36 |
| eu-west-1 | eu-west-1a        | c6i.2xlarge   |   0.221100 | 2026-01-16 15:01:39 |
| eu-west-1 | eu-west-1c        | c6i.2xlarge   |   0.225900 | 2026-01-16 14:01:34 |
| eu-west-1 | eu-west-1a        | c6i.2xlarge   |   0.221300 | 2026-01-16 09:16:28 |
| eu-west-1 | eu-west-1b        | c6i.2xlarge   |   0.235700 | 2026-01-16 07:46:39 |
| eu-west-1 | eu-west-1c        | c6i.2xlarge   |   0.225700 | 2026-01-16 07:01:44 |
| eu-west-1 | eu-west-1b        | c6i.2xlarge   |   0.235600 | 2026-01-16 04:32:26 |