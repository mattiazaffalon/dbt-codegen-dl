# dbt-codegen-dl
## Prepare your Python environment
**Prerequisite** Make sure you have python 3.8+ intalled on your system

In a command shell, execute the following commands in the root directory of the project:
```bash
python3.[x] -m venv .venv

source .venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt
```

## Setup dbt environment
In order to use dbt cli, you need to setup a profiles.yml file to tell dbt how to connect to the database target of the transformations. Follow this link for details on how to create the profiles.yml file that suits your needs: https://docs.getdbt.com/reference/profiles.yml.

Below is a sample profile used to connect to a BigQuery dataset:
```
dbt_codegen_dl:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      keyfile: <full path of a service account key file>
      project: <gcp project>
      dataset: <gcp dataset>
      threads: 1
      timeout_seconds: 300
      location: <location>
      priority: interactive
```

## Fetch dbt dependencies
```bash
dbt deps
```

## stage external tables
```bash
dbt run-operation stage_external_sources --vars "ext_full_refresh: true"
```

## Launching model generation macro
```bash
bin/gen_dl_model.sh --forceoverwrite models/dl/crm/crm__sources.yml crm feed1
```

(to run the macro and print the results on stdout)
```bash
dbt run-operation gen_dl_model --args '{"source_name": "crm", "source_relation": "feed1"}'
```

## Running the generated models
```bash
dbt test --select source:crm.feed1 && \
    dbt snapshot --select source:crm.feed1+  && \
    dbt run --select source:crm.feed1+ --full-refresh && \
    dbt test --select dl_crm__feed1
```
