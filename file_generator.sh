#!/bin/bash

main() {
    name_file_chars=""
    expansion_file_chars=""
    date=$(date +"%d%m%y")
    validate_parameters "$@"
    create_base_directory "$1"

    generate_dir_file "$@"
}

create_base_directory() {
    local base_path="$1"
    
    if [[ ! -d "$base_path" ]]; then
        echo "Создание базовой директории: $base_path"
        mkdir -p "$base_path" || {
            echo "Ошибка: Не удалось создать директорию $base_path"
            exit 1
        }
    fi
    
    cd "$base_path" || {
        echo "Ошибка: Не удалось перейти в директорию $base_path"
        exit 1
    }
}

check_disk_space() {
    local available_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [[ $available_gb -le 1 ]]; then
        echo "ОСТАНОВ: Свободного места осталось 1 ГБ или меньше"
        exit 1
    fi
}

check_alph_for_dir() {
    if (( ${#1} < 0 || ${#1} > 7 )); then
        echo "Error: Еhe alphabet must be from 0 to 7"
        exit 1
    fi

    if [[ ! $1 =~ ^[a-zA-Z]+$ ]]; then
        echo "Parameter '$1' contains non-alphabetic characters"
        exit 1
    fi
}

check_alph_for_file() {
    if [[ ! $1 =~ ^[a-zA-Z]+.[a-zA-Z]+$ ]]; then
        echo "Parameter '$1' contains non-alphabetic characters"
        exit 1
    else
        name_file_chars="${1%.*}"
        expansion_file_chars="${1#*.}"
    fi

    if (( ${#name_file_chars} < 0 || ${#expansion_file_chars} < 0 || ${#name_file_chars} > 7 || ${#expansion_file_chars} > 3 )); then
        echo "Error: no more than 7 characters for the file name, no more than 3 characters for the extension"
        exit 1
    fi
}

check_file_size() {
    if [[ ! $1 =~ ^[0-9]+kb$ ]]; then
        echo "Error: Enter size file in the view of 'Nkb', where N from 0 to 100"
        exit 1
    else
        file_size="${1%kb}"
    fi

    if (( file_size < 0 || file_size > 100 )); then
        echo "Error: Enter size file from 0 to 100 kb"
        exit 1
    fi
}

validate_parameters() {
    if [ $# -lt 6 ]; then
        echo "Error: Enter parametrs"
        echo "Parameter 1 is the absolute path"
        echo "Parameter 2 is the number of subfolders" 
        echo "Parameter 3 is the list of letters of the English alphabet used in the folder names (no more than 7 characters)"
        echo "Parameter 4 is the number of files in each created folder"
        echo "Parameter 5 is the list of letters of the English alphabet used in the file name and extension (no more than 7 characters for the name, no more than 3 characters for the extension)"
        echo "Parameter 6 is the file size (in kilobytes, but not more than 100)"
        exit 1
    fi

    if [[ ! $2 =~ ^-?[0-9]+$ ]]; then 
        echo "Error: The second parameter is not a number"
        exit 1
    fi
    
    check_alph_for_dir $3

    if [[ ! $4 =~ ^-?[0-9]+$ ]]; then 
        echo "Error: The fourth parameter is not a number"
        exit 1
    fi

    check_alph_for_file $5
    check_file_size $6
}

generate_name() (
    local chars="$1"
    local suffix="$2"
    local is_expansion="$3"
    local coef=0

    while (( ${#name} < 4 )); do
        local name=""
        ((coef++))
        for ((i=0; i<${#chars}; i++)); do
            rand_count=$(( $coef + RANDOM % ($coef + 1) ))
            for (( j=0; j< $rand_count; j++ )); do
                name="${name}${chars:$i:1}"
            done
        done
    done

    if [ $is_expansion -eq "1" ]; then
        echo "${name}"
    else
        echo "${name}_${suffix}"
    fi
    
)

generate_dir_file() {
    local base_path="$1"
    local dir_count="$2"
    local dir_chars="$3"
    local file_count="$4"
    local file_chars="$5"

    touch "script.log"

    for (( i=0; i<"$dir_count"; i++ )); do
        check_disk_space
        
        local dir_name=$(generate_name "$dir_chars" "$date" "0")

        mkdir -p "$dir_name" || {
            echo "Ошибка: Не удалось создать директорию $dir_name"
            exit 1
        }

        for (( j=0; j<"$file_count"; j++ )); do
            check_disk_space
            
            local name_file=$(generate_name "$name_file_chars" "$date" "0")
            local expansion_file=$(generate_name "$expansion_file_chars" "$date" "1")
            local full_file_path="${dir_name}/${name_file}.${expansion_file}"

            dd if=/dev/zero of="$full_file_path" bs=1K count="$file_size" status=none 2>/dev/null || {
                echo "Ошибка: Не удалось создать файл $full_file_path"
                exit 1
            }

            echo "$full_file_path $(date +%d.%m.%y_%H:%M:%S) $6" >> "script.log"
        done
    done
}

main "$@"