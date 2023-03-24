# dbt-codegen-dl

## Init the project
```bash
dbt deps
```

## stage external tables
```bash
dbt run-operation stage_external_sources --vars "ext_full_refresh: true"
```

## Launching model generation macro
```bash
bin/gen_dl_model.sh --forceoverwrite models/staging/crm/crm__sources.yml crm feed1
```

(to run the macro and print the results on stdin)
```bash
dbt run-operation gen_dl_model --args '{"source_name": "crm", "source_relation": "feed1"}'
```

## Running the generated models

## Launching tests
on sources
```bash
dbt test --select source:crm.feed1 && \
    dbt snapshot --select source:crm.feed1+  && \
    dbt run --select source:crm.feed1+ --full-refresh && \
    dbt test --select dl_crm__feed1
```

## Development

### Local environment setup (on Ubuntu)

**Prerequisite** Make sure you have python3.8 intalled on your system

In a command shell, execute the following command in the root directory of the project:
```bash
python3.8 -m venv .venv

source .venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt