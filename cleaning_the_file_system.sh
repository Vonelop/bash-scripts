#!/bin/bash

main() {
    local type=$1

    validate_parameters "$@"

    clear_file_sys $type
}

validate_parameters() {
    local type=$1

    if [[ $# -lt 1 ]]; then
        echo "Error: Enter type of system cleaning (1, 2, 3)"
        exit 1
    fi

    if (( $type != 1 && $type != 2 && $type != 3 )); then
        echo "Error: Enter type of system cleaning (1, 2, 3)"
        exit 1
    fi
}

validate_date_format() {
    local date=$1

    if [[ $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_mask_format() {
    local mask=$1

    if [[ $mask =~ ^[a-zA-Z]+_[0-9]{6}$ ]]; then
        return 0
    else
        return 1
    fi
}

clear_file_sys() {
    local type=$1

    if (( $type == 1 )); then
        clear_by_log_file
    elif (( $type == 2 )); then
        clear_by_date
    elif (( $type == 3 )); then
        clear_by_mask
    fi
}

clear_by_log_file() {
    echo -n "Enter path log file: "
    read -r path

    if [[ -f "$path" ]]; then
        local path_log_file=$path
    else
        echo "Error: Log file does not exist"
        exit 1
    fi

    for path_unnecessary_file in $(cat $path_log_file | awk '{print $1}'); do
        if [[ -f "$path_unnecessary_file" ]]; then
            if rm $path_unnecessary_file 2>/dev/null; then
                echo "The file $path_unnecessary_file has been deleted"
            else
                echo "Couldn't delete file $path_unnecessary_file"
            fi
        fi
    done
}

clear_by_date() {
    echo -n "Enter path log file: "
    read -r path

    if [[ -f "$path" ]]; then
        local path_log_file=$path
    else
        echo "Error: Log file does not exist"
        exit 1
    fi

    echo -n "Enter start time for search in format YYYY-MM-DD HH:MM: "
    read -r start_time

    echo -n "Enter start time for search in format YYYY-MM-DD HH:MM: "
    read -r end_time

    if validate_date_format "$start_time" && validate_date_format "$end_time"; then
        if [[ "$start_time" > "$end_time" ]]; then
            echo "Error: Start time must be earlier than end time"
            exit 1
        fi

        while IFS= read -r line; do
            local path_unnecessary_file=$(echo "$line" | awk '{print $1}')
            local date_u_f=$(echo "$line" | awk '{print $2}')
            local time_u_f=$(echo "$line" | awk '{print $3}')

            if [[ "$date_u_f $time_u_f" > "$start_time" && "$date_u_f $time_u_f" < "$end_time" ]]; then
                if rm $path_unnecessary_file 2>/dev/null; then
                    echo "The file $path_unnecessary_file has been deleted"
                else
                    echo "Couldn't delete file $path_unnecessary_file"
                fi
            fi
        done < "$path_log_file"
    else
        echo "Enter date in format YYYY-MM-DD HH:MM"
        exit 1
    fi
}

clear_by_mask() {
    echo -n "Enter path log file: "
    read -r path

    if [[ -f "$path" ]]; then
        local path_log_file=$path
    else
        echo "Error: Log file does not exist"
        exit 1
    fi

    echo -n "Enter mask file in format chars_DDMMYY: "
    read -r mask

    if validate_mask_format "$mask"; then
        for path_unnecessary_file in $(cat $path_log_file | awk '{print $1}'); do
            file_name_with_exit=$(basename $path_unnecessary_file)
            file_name_without_exit="${file_name_with_exit%.*}"
            
            if [[ "$file_name_without_exit" == "$mask" ]]; then
                if rm $path_unnecessary_file 2>/dev/null; then
                    echo "The file $path_unnecessary_file has been deleted"
                else
                    echo "Couldn't delete file $path_unnecessary_file"
                fi
            fi
        done
    fi
}

main "$@"