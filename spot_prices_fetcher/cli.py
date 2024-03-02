import datetime
import gzip
from pathlib import Path
from typing import Annotated

import boto3
import orjson
import pydantic
from dateutil.tz import tzutc
from mypy_boto3_ec2 import EC2Client
from typer import Typer, Argument

app = Typer()


class State(pydantic.BaseModel):
    regions: dict[str, datetime.date]


@app.command()
def fetch(
        state_file: Path = Path("state.json"),
        output_directory: Path = Path("spot_price_data/"),
):
    ec2: EC2Client = boto3.client("ec2")
    region_response = ec2.describe_regions(
        Filters=[
            {"Name": "opt-in-status", "Values": ["opt-in-not-required", "opted-in"]}
        ]
    )

    if state_file.exists():
        state = State.model_validate_json(state_file.read_text())
    else:
        state = State(regions={})

    regions = [region["RegionName"] for region in region_response["Regions"]]
    print(f"Fetching data for regions {regions}")
    for region in regions:
        last_fetched_date = state.regions.get(
            region, datetime.date.today() - datetime.timedelta(days=50)
        )
        date_to_fetch = last_fetched_date + datetime.timedelta(days=1)

        region_directory = output_directory / f"region={region}"
        region_directory.mkdir(exist_ok=True, parents=True)
        output_path = region_directory / f"{date_to_fetch}.jsonl.gz"

        fetch_date(
            day=datetime.datetime.combine(date_to_fetch, datetime.time.min).astimezone(
                tzutc()
            ),
            region=region,
            output_path=output_path,
        )
        state.regions[region] = date_to_fetch

    state_file.write_text(state.model_dump_json())


@app.command()
def fetch_date(
        day: Annotated[
            datetime.datetime,
            Argument(formats=["%Y-%m-%d"]),
        ],
        region: str,
        output_path: Path,
):
    ec2: EC2Client = boto3.client("ec2", region_name=region)
    paginator = ec2.get_paginator("describe_spot_price_history")
    start_timestamp = datetime.datetime.combine(day, datetime.time.min).astimezone(
        tzutc()
    )
    end_timestamp = datetime.datetime.combine(day, datetime.time.max).astimezone(
        tzutc()
    )
    print(f"Fetching spot prices for {day.date()} in {region}")
    results = [
        {
            "AvailabilityZone": item["AvailabilityZone"],
            "InstanceType": item["InstanceType"],
            "SpotPrice": item["SpotPrice"],
            "Timestamp": item["Timestamp"],
        }
        for page in paginator.paginate(
            StartTime=start_timestamp,
            EndTime=end_timestamp,
            ProductDescriptions=["Linux/UNIX"],
        )
        for item in page["SpotPriceHistory"]
        if start_timestamp <= item["Timestamp"] < end_timestamp
    ]
    print(f"Got {len(results)} results")
    sorted_results = sorted(results, key=lambda x: x["Timestamp"])
    to_write = b"\n".join(orjson.dumps(result) for result in sorted_results)
    if output_path.name.endswith('.gz'):
        to_write = gzip.compress(to_write)
    output_path.write_bytes(to_write)


if __name__ == "__main__":
    app()
