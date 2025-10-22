#!/bin/bash

main() {
    local type=$1
    local files=("../04/nginx_access_1.log" "../04/nginx_access_2.log" "../04/nginx_access_3.log" "../04/nginx_access_4.log" "../04/nginx_access_5.log")
    local combined_content=""

    for file in "${files[@]}"; do
        combined_content+=$(cat "$file")
        combined_content+=$'\n'
    done

    validate_parameter $type

    case $type in
        "1")
            print_sord_records "$combined_content"
            ;;
        "2")
            print_uniq_ip "$combined_content"
            ;;
        "3")
            print_error_records "$combined_content"
            ;;
        "4")
            print_uniq_ip_error_records "$combined_content"
            ;;
    esac
}

validate_parameter() {
    local parameter="$1"

    if [[ $# -lt 1 ]]; then
        echo "Error: Enter parameter(1 2 3 4)"
        exit 1
    fi

    if (( "$parameter" != 1 && "$parameter" != 2 && "$parameter" != 3 && "$parameter" != 4 )); then
        echo "Error: Enter parameter(1 2 3 4)"
        exit 1
    fi
}

print_sord_records() {
    local combined_content="$1"

    echo "$combined_content" | sort -k9,9n | nl
}

print_uniq_ip() {
    local combined_content="$1"

    echo "$combined_content" | awk '{print $1}' | sort | uniq
}

print_error_records() {
    local combined_content="$1"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        local code_req=$(echo $line | awk '{print $9}')

        if [[ $code_req =~ ^[45][0-9]{2}$ ]]; then
            error_content+="$line"$'\n'
        fi
    done < <(echo "$combined_content")

    echo "$error_content" | nl
}

print_uniq_ip_error_records() {
    local combined_content="$1"

    print_error_records "$combined_content" | awk '{print $1}' | sort | uniq | nl
}

main "$@"