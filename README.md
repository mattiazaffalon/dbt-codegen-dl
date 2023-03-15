# dbt-codegen-dl

## Init the project
```bash
dbt deps
```

## Launching model generation macro
```bash
bin/gen_dl_model.sh --forceoverwrite models/staging/crm/crm__sources.yml crm feed1
```

## Running the generated models


## Development

### Local environment setup (on Ubuntu)

**Prerequisite** Make sure you have python3.8 intalled on your system

In a command shell, execute the following command in the root directory of the project:
```bash
python3.8 -m venv .venv

source .venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt