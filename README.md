# dbt-codegen-dl

## Launching model generation macro
```bash
dbt run-operation gen_dl_model --args '{"source_name": "crm", "source_relation": "feed1"}'
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