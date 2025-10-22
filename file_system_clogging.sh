#!/bin/bash

main() {
    local start_time=$(date +%s.%N)

    local dir_chars="$1"
    local file_chars="$2"
    local file_size="$3"
    local date=$(date +"%d%m%y")
    name_file_chars=""
    expansion_file_chars=""
    num_file_size=""

    validate_parameters $dir_chars $file_chars $file_size
    clog_up_file_sys $dir_chars $name_file_chars $expansion_file_chars $num_file_size $date

    local end_time=$(date +%s.%N)
    local execution_time=$(echo "$end_time - $start_time" | bc) 
    echo "START TIME RUNING SCRIPT: $start_time" >> "script.log"
    echo "END TIME RUNING SCRIPT: $end_time" >> "script.log"
    echo "END TIME RUNING SCRIPT: $(printf "%.1f" $execution_time)s" >> "script.log"
}

validate_dir_chars() {
    local chars=$1

    if (( ${#chars} < 0 || ${#chars} > 7 )); then
        echo "Error: Еhe alphabet must be from 0 to 7"
        exit 1
    fi

    if [[ ! $chars =~ ^[a-zA-Z]+$ ]]; then
        echo "Parameter '$chars' contains non-alphabetic characters"
        exit 1
    fi
}

validate_file_chars() {
    local chars=$1

    if [[ ! $chars =~ ^[a-zA-Z]+.[a-zA-Z]+$ ]]; then
        echo "Parameter '$1' contains non-alphabetic characters"
        exit 1
    else
        name_file_chars="${chars%.*}"
        expansion_file_chars="${chars#*.}"
    fi

    if (( ${#name_file_chars} < 0 || ${#expansion_file_chars} < 0 || ${#name_file_chars} > 7 || ${#expansion_file_chars} > 3 )); then
        echo "Error: no more than 7 characters for the file name, no more than 3 characters for the extension"
        exit 1
    fi
}

validate_file_size() {
    local file_size=$1

    if [[ ! $file_size =~ ^[0-9]+Mb$ ]]; then
        echo "Error: Enter size file in the view of 'Nkb', where N from 0 to 100"
        exit 1
    else
        num_file_size="${1%Mb}"
    fi

    if (( num_file_size < 0 || num_file_size > 100 )); then
        echo "Error: Enter size file from 0 to 100 Mb"
        exit 1
    fi
}

validate_parameters() {
    local dir_chars="$1"
    local file_chars="$2"
    local file_size="$3"

    if [ $# -lt 3 ]; then
        echo "Error: Enter parametrs"
        echo "Parameter 1 is the list of letters of the English alphabet used in the folder names (no more than 7 characters)"
        echo "Parameter 2 is the list of letters of the English alphabet used in the file name and extension (no more than 7 characters for the name, no more than 3 characters for the extension)"
        echo "Parameter 3 is the file size (in Megabytes, but not more than 100)"
        exit 1
    fi

    validate_dir_chars "$dir_chars"
    validate_file_chars "$file_chars"
    validate_file_size "$file_size"
}

check_disk_space() {
    local available_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [[ $available_gb -le 1 ]]; then
        # echo "ОСТАНОВ: Свободного места осталось 1 ГБ или меньше"
        echo "0"
    else
        echo "1"
    fi
}

generate_name() {
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
}

create_files() {
    local name_file_chars="$1"
    local expansion_file_chars="$2"
    local num_file_size="$3"
    local date="$4"
    local path_new_dir="$5"

    local count_files=$(( 1 + RANDOM % 99 ))

    for (( j=0; j<$count_files; j++)); do
        if [[ $(check_disk_space) == "0" ]]; then
            break
        fi

        local name_file=$(generate_name "$name_file_chars" "$date" "0")
        local expansion_file=$(generate_name "$expansion_file_chars" "$date" "1")
        local full_file_path="$path_new_dir/${name_file}.${expansion_file}"

        if [[ ! -f "$full_file_path" ]]; then
            if dd if=/dev/zero of="$full_file_path" bs=1M count="$num_file_size" status=none 2>/dev/null; then
                echo "$full_file_path has been created"
                echo "$full_file_path $(date +%Y-%m-%d) $(date +%H:%M) $num_file_size Mb" >> "script.log"
            else
                break
            fi
        else
            break
        fi
    done
}

create_dir_with_files() {
    local dir_chars="$1"
    local name_file_chars="$2"
    local expansion_file_chars="$3"
    local num_file_size="$4"
    local date="$5"
    local path="$6"

    if [[ ! $path =~ /bin/ ]] && [[ ! $path =~ /sbin/ ]]; then
        local count_dirs=$(( 1 + RANDOM % 99 ))
        
        for (( i=0; i<$count_dirs; i++)); do
            if [[ $(check_disk_space) == "0" ]]; then
                break
            fi

            local dir_name=$(generate_name "$dir_chars" "$date" "0")

            if mkdir -p "$path/$dir_name" 2>/dev/null; then
                create_files $name_file_chars $expansion_file_chars $num_file_size $date "$path/$dir_name"
            else
                break
            fi
        done
    fi
}

clog_up_file_sys() {
    local dir_chars="$1"
    local name_file_chars="$2"
    local expansion_file_chars="$3"
    local num_file_size="$4"
    local date="$5"
    
    local clogged_path="/"
    local available_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')

    find "$clogged_path" -mindepth 1 -type d -writable 2>/dev/null | while read -r path; do
        if [[ $(check_disk_space) == "0" ]]; then
            echo "STOP: There is 1 GB or less of free space left"
            break
        fi

        if [ -d "$path" ] && [ -w "$path" ] && [ -x "$path" ]; then
            create_dir_with_files $dir_chars $name_file_chars $expansion_file_chars $num_file_size $date $path
        fi
        
    done
}

main "$@"


