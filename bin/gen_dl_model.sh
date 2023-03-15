#!/bin/bash

force_overwrite=false

if [[ $1 == "--forceoverwrite" ]]; then
    force_overwrite=true
    shift
fi

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 [--forceoverwrite] <sources config file path> <source name> <relation name>"
    exit 1
fi

file_path=$1
source_name=$2
relation_name=$3

if [ ! -f "$file_path" ]; then
    echo "Error: file '$file_path' does not exist"
    exit 1
fi

echo "Your file path: $file_path"
echo "Source Name: $source_name"
echo "Relation Name: $relation_name"

output=$(dbt run-operation gen_dl_model --args "{\"source_name\": \"$source_name\", \"source_relation\": \"$relation_name\"}")

write_block() {
    echo "Writing file $1"
    local target_file=$1
    if [ -f "$target_file" ] && ! $force_overwrite; then
        echo "Error: the file '$target_file' already exists. Use --forceoverwrite to overwrite it."
        exit 1
    fi
    echo "$block_content" > "$target_file"
}

inside_code_block=false
block_content=""

while IFS= read -r line; do
    if [[ $line == "#codegenmodule"* ]]; then
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
            block_content=""
        else
            inside_code_block=true
        fi

        json_string=${line#* }
        type=$(echo "$json_string" | jq -r '.type')
        filename=$(echo "$json_string" | jq -r '.filename')
    elif $inside_code_block; then
        block_content+="$line"$'\n'
    fi
done <<< "$output"

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
        "config")
            write_block "$(dirname "$file_path")/$filename"
            ;;
    esac
fi
