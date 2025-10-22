#!/bin/bash

export LANG=C
export LC_NUMERIC=C

main() {
    for (( i=1; i<=5; i++ )); do
        local file_name="nginx_access_$i.log"

        touch "$file_name"
        
        local count_records=$(( 100 + RANDOM % 901 ))
        local date="$(generate_date):00:01:00"

        for (( j=1; j<=count_records; j++ )); do
            local ip=$(generate_ip)
            local method=$(generate_method)
            local code_req=$(generate_code_req $method)
            local url=$(generate_url)
            local agent=$(generate_agent)
            local date=$(increase_log_date "$date" "1 minutes")

            echo "$ip - - [$date +0300] \"$method $url HTTP/1.1\" $code_req - \"-\" \"$agent\"" >> $file_name
        done
    done

    echo "Log files have been created"
}

generate_ip() {
    echo "$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))"
}

generate_code_req() {
    # 200 - Успешный запрос
    # 201 - Успешный запрос и создан новый ресурс
    # 400 - Сервер не может обработать запрос из-за клиентской ошибки
    # 401 - Требуется аутентификация
    # 403 - Доступ запрещен (авторизован, но нет прав)
    # 404 - Ресурс не найден
    # 500 - Общая ошибка сервера
    # 501 - Сервер не поддерживает функциональность для выполнения запроса
    # 502 - Сервер действовал как шлюз и получил неверный ответ
    # 503 - Сервис временно недоступен

    local method=$1

    case $method in
        "GET") 
            local code_reqs=("200" "400" "401" "403" "404" "500" "501" "502" "503")
            ;;
        "POST")
            local code_reqs=("200" "201" "400" "401" "403" "404" "500" "501" "502" "503")
            ;;
        "PUT")
            local code_reqs=("200" "201" "400" "401" "403" "404" "500" "501" "502" "503")
            ;;
        "DELETE")
            local code_reqs=("200" "400" "401" "403" "404" "500" "501" "502" "503")
            ;;
        "PATCH")
            local code_reqs=("200" "400" "401" "403" "404" "500" "501" "502" "503")
            ;;
    esac

    echo "${code_reqs[$RANDOM % ${#code_reqs[@]}]}"
}

generate_method() {
    local methods=("GET" "POST" "PUT" "DELETE" "PATCH")

    echo "${methods[$RANDOM % ${#methods[@]}]}"
}

generate_date() {
    local months=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")

    echo "$((RANDOM % 29))/${months[$RANDOM % ${#months[@]}]}/2025"
}

generate_agent() {
    local agents=("Safari/14.0" "Firefox/89.0" "Chrome/91.0" "Mozilla/5.0")

    echo "${agents[$RANDOM % ${#agents[@]}]}"
}

generate_url() {
    local domains=("https://google.com" "https://yandex.ru" "https://example.com" "https://facebook.com" "https://twitter.com" "https://linkedin.com")
    local paths=("" "search" "results" "page" "article" "post" "image")
    local params=("" "?q=nginx" "?id=123" "?page=2" "?sort=date" "?filter=new")
    
    local domain=${domains[$RANDOM % ${#domains[@]}]}
    local path=${paths[$RANDOM % ${#paths[@]}]}
    local param=${params[$RANDOM % ${#params[@]}]}
    
    if [[ -z "$path" ]]; then
        echo "$domain$param"
    else
        echo "$domain/$path$param"
    fi
}

increase_log_date() {
    local log_date="$1"
    local increment="$2"
    
    local day=$(echo "$log_date" | cut -d'/' -f1)
    local month=$(echo "$log_date" | cut -d'/' -f2)
    local year_time=$(echo "$log_date" | cut -d'/' -f3)
    local year=$(echo "$year_time" | cut -d':' -f1)
    local hour=$(echo "$year_time" | cut -d':' -f2)
    local minute=$(echo "$year_time" | cut -d':' -f3)
    local second=$(echo "$year_time" | cut -d':' -f4)
    
    local normalized_date="$day $month $year $hour:$minute:$second"
    
    date -d "$normalized_date $increment" +'%d/%b/%Y:%H:%M:%S'
}

main "$@"