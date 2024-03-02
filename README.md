# Spot Prices

This repo contains historic and present AWS Spot prices for all publicly available regions.

Data is available in three formats:
1. Raw, gzip-compressed JSON inside the [spot_price_data](./spot_price_data) directory
2. A single Parquet file from https://github.com/orf/spot-prices/releases/download/latest/history.parquet
3. A gzip-compressed sqlite database from https://github.com/orf/spot-prices/releases/download/latest/history.sqlite.gz
