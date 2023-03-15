#!/bin/bash

force_overwrite=false

# Controlla se l'opzione --forceoverwrite è stata fornita
if [[ $1 == "--forceoverwrite" ]]; then
    force_overwrite=true
    shift
fi

# Controlla se il numero di parametri passati è corretto (3 parametri)
if [ "$#" -lt 3 ]; then
    echo "Uso: $0 [--forceoverwrite] <path_del_file> <source_name> <relation_name>"
    exit 1
fi

file_path=$1
source_name=$2
relation_name=$3

# Controlla se il file esiste
if [ ! -f "$file_path" ]; then
    echo "Errore: il file '$file_path' non esiste."
    exit 1
fi

echo "Hai specificato il file: $file_path"
echo "Source Name: $source_name"
echo "Relation Name: $relation_name"

# Esegue il comando dbt run-operation con i parametri source_name e relation_name
output=$(dbt run-operation gen_dl_model --args "{\"source_name\": \"$source_name\", \"source_relation\": \"$relation_name\"}")

# Funzione per scrivere il contenuto del blocco corrente in un file
write_block() {
    echo "Writing file $1"
    local target_file=$1
    if [ -f "$target_file" ] && ! $force_overwrite; then
        echo "Errore: il file '$target_file' esiste già. Usa --forceoverwrite per sovrascriverlo."
        exit 1
    fi
    echo "$block_content" > "$target_file"
}

# Inizializza le variabili
inside_code_block=false
block_content=""

# Legge l'output riga per riga
while IFS= read -r line; do
    if [[ $line == "#codegenmodule"* ]]; then
        if $inside_code_block; then
            # Scrive il contenuto del blocco corrente in un file
            case $type in
                "base")
                    mkdir -p "$(dirname "$file_path")/base"
                    write_block "$(dirname "$file_path")/base/$filename"
                    ;;
                "stg")
                    write_block "$(dirname "$file_path")/$filename"
                    ;;
                "snapshot")
                    mkdir -p "./snapshots/$source_name"
                    write_block "./snapshots/$source_name/$filename"
                    ;;
            esac
            block_content=""
        else
            inside_code_block=true
        fi

        # Estrae il JSON dalla riga e ne ricava i valori "type" e "filename"
        json_string=${line#* }
        type=$(echo "$json_string" | jq -r '.type')
        filename=$(echo "$json_string" | jq -r '.filename')
    elif $inside_code_block; then
        block_content+="$line"$'\n'
    fi
done <<< "$output"

# Scrive l'ultimo blocco di contenuto in un file, se necessario
if $inside_code_block; then
    case $type in
        "base")
            mkdir -p "$(dirname "$file_path")/base"
            write_block "$(dirname "$file_path")/base/$filename"
            ;;
        "stg")
            write_block "$(dirname "$file_path")/$filename"
            ;;
        "snapshot")
            mkdir -p "./snapshots/$source_name"
            write_block "./snapshots/$source_name/$filename"
            ;;
    esac
fi
