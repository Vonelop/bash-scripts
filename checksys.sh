#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

internet_status="${RED}Не подключен${NC}"
firewall_status="${RED}Не установлен${NC}"
antivirus_status="${RED}Не установлен${NC}"
firewall_run_status="${RED}Не работает${NC}"
antivirus_run_status="${RED}Не работает${NC}"

main() {
    num=$1

    if [ $# -eq 0 ]; then
        echo "============================================"
        echo "  Инструменты проверки безопасности Ubuntu  "
        echo "============================================"
        echo "Меню:"
        echo "1 - Проверка интернета"
        echo "2 - Проверка наличия установленного межсетевого экрана и антивируса"
        echo "3 - Проверка работоспособности межсетевого экрана"
        echo "4 - Проверка работоспособности антивирусного ПО"
        echo "5 - Проверить все"
        read -p "Введите аргумент (1-5): " num

        valid_arg $num

        echo

        tools $num
    else
        valid_arg $1
        tools $1
    fi

    echo
    echo "--------------- РЕЗУЛЬТАТЫ ---------------"
    if [[ $num -eq 1 || $num -eq 5 ]]; then
        echo -e "Интернет: $internet_status"
    fi
    
    if [[ $num -eq 2 || $num -eq 5 ]]; then
        echo -e "Межсетевой экран: $firewall_status"
        echo -e "Антивирус: $antivirus_status"
    fi
    
    if [[ $num -eq 3 || $num -eq 5 ]]; then
        echo -e "Работоспособность МЭ: $firewall_run_status"
    fi
    
    if [[ $num -eq 4 || $num -eq 5 ]]; then
        echo -e "Работоспособность антивируса: $antivirus_run_status"
    fi
    echo "------------------------------------------"
}

valid_arg() {
    local input="$1"
    local valid_choices=("1" "2" "3" "4" "5")
    
    for choice in "${valid_choices[@]}"; do
        if [ "$input" = "$choice" ]; then
            return 0
        fi
    done

    return 1
}

tools() {
    local num=$1

    case $num in
    1)
        check_internet
        ;;
    2)  
        check_firewall_antivirus
        ;;
    3)  
        check_run_firewall
        ;;
    4)  
        check_run_antivirus
        ;;
    5)  
        check_internet
        check_firewall_antivirus
        check_run_firewall
        check_run_antivirus
        ;;
    esac
}

check_internet() {
    echo -n "Проверка подключения к Интернету... "

    if ping -c 2 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}[ OK ]${NC}"
        internet_status="${GREEN}Подключен${NC}"
    else
        echo -e "${RED}[ FAIL ]${NC}"
    fi
}

check_firewall_antivirus() {
    echo -n "Проверка наличия установленного межсетевого экрана... "

    if command -v iptables &> /dev/null; then
        echo -e "${GREEN}[ OK ]${NC}"
        firewall_status="${GREEN}Установлен${NC}"
    else
        echo -e "${RED}[ FAIL ]${NC}"
    fi

    echo -n "Проверка наличия установленного антивируса... "

    if command -v clamscan &> /dev/null; then
        echo -e "${GREEN}[ OK ]${NC}"
        antivirus_status="${GREEN}Установлен${NC}"
    else
        echo -e "${RED}[ FAIL ]${NC}"
    fi
}

check_run_firewall() {
    echo -n "Проверка работоспособности межсетевого экрана... "

    if iptables -L -n &>/dev/null; then
        echo -e "${GREEN}[ OK ]${NC}"
        firewall_run_status="${GREEN}Работает${NC}"
    else
        echo -e "${RED}[ FAIL ]${NC}"
    fi
}

check_run_antivirus() {
    echo -n "Проверка работоспособности антивируса... "

    local test_file="./eicar.com"
    local test_content='X5O!P%%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
    
    printf $test_content > $test_file
    
    echo -e "${YELLOW}[ ТЕСТ ]${NC}"
    echo -e "   - Создание тестового файла: ${YELLOW}$test_file${NC}"
    echo -n "   - Сканирование тестового файла: "
    
    local scan_result=$(clamscan "$test_file" 2>&1)
    
    if echo "$scan_result" | grep "Eicar" &>/dev/null; then
        echo -e "${GREEN}УГРОЗА ОБНАРУЖЕНА${NC}"
        antivirus_run_status="${GREEN}Работает${NC}"
    else
        echo -e "${RED}УГРОЗА НЕ ОБНАРУЖЕНА${NC}"
        
        rm -f "$test_file"
        echo -e "   ${BLUE}Тестовый файл удален${NC}"
    fi
}

main $*