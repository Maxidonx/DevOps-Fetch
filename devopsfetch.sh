#!/bin/bash

# Function to display help information
display_help() {
    echo "Usage: devopsfetch [OPTION]..."
    echo "Retrieve and display system information"
    echo "Options:"
    echo "  -p, --port [PORT]     Display active ports or specific port info"
    echo "  -d, --docker [NAME]   Display Docker images/containers or specific container info"
    echo "  -n, --nginx [DOMAIN]  Display Nginx domains or specific domain config"
    echo "  -u, --users [USER]    Display user logins or specific user info"
    echo "  -t, --time [START] [END]  Display activities within a specified time range"
    echo "  -h, --help            Display this help message"
}

# Function to log activities to a file
log_activity() {
    local log_file="/tmp/devopsfetch.log"
    local max_size=$((10 * 1024 * 1024))  # 10 MB

    # Create log file if it doesn't exist
    if [ ! -f "$log_file" ]; then
        touch "$log_file"
        chmod 644 "$log_file"
    fi

    # Rotate log file if it exceeds max size
    if [ "$(stat -c %s "$log_file")" -gt "$max_size" ]; then
        mv "$log_file" "${log_file}.old"
        touch "$log_file"
        chmod 644 "$log_file"
    fi

    # Append log entry
    echo "$(date): $1" >> "$log_file"
}

# Function to get port information
get_port_info() {
    if [ -z "$1" ]; then
        echo "Active and closed ports, services, and processes:"
        (
            printf "+------------+---------------+-------------------------+--------------------+\n"
            printf "| Protocol   | PORT          | State                   | Program Name       |\n"
            printf "+------------+---------------+-------------------------+--------------------+\n"
            lsof -i -P -n | grep LISTEN | awk '{split($9,a,":"); printf "| %-10s | %-13s | %-23s | %-18s |\n", $1, a[length(a)], $10, $2 "/" $1}'
            lsof -i -P -n | grep -v LISTEN | awk '{split($9,a,":"); printf "| %-10s | %-13s | %-23s | %-18s |\n", $1, a[length(a)], $10, $2 "/" $1}'
            printf "+------------+---------------+-------------------------+--------------------+\n"
        )
    else
        echo "Information for port $1:"
        (
            printf "+------------+---------------+-------------------------+--------------------+\n"
            printf "| Protocol   | PORT          | State                   | Program Name       |\n"
            printf "+------------+---------------+-------------------------+--------------------+\n"
            ss -tuln | grep ":$1 " | while read -r line; do
                protocol=$(echo "$line" | awk '{print $1}')
                port=$(echo "$line" | awk '{split($4,a,":"); print a[length(a)]}')
                state=$(echo "$line" | awk '{print $2}')

                pid=$(lsof -i :$1 -sTCP:LISTEN -t -n -P 2>/dev/null)
                if [ -n "$pid" ]; then
                    program=$(ps -o comm= -p "$pid")
                else
                    program="N/A"
                fi

                printf "| %-10s | %-13s | %-23s | %-18s |\n" "$protocol" "$port" "$state" "$program"
            done
            printf "+------------+---------------+-------------------------+--------------------+\n"
        )
    fi
}

# Function to get Docker information
get_docker_info() {
    if [ -z "$1" ]; then
        echo "Docker images:"
        (
            printf "+------------------------------+----------------------+----------------------+--------------+\n"
            printf "| Repository                   | Tag                  | ID                   | Size         |\n"
            printf "+------------------------------+----------------------+----------------------+--------------+\n"
            docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | awk '{printf "| %-28s | %-20s | %-20s | %-12s |\n", $1, $2, $3, $4}'
            printf "+------------------------------+----------------------+----------------------+--------------+\n"
        )
        echo -e "\nDocker containers:"
        (
            printf "+--------------------+------------------------------+----------------------+------------------------------+\n"
            printf "| Names              | Image                        | Status               | Ports                        |\n"
            printf "+--------------------+------------------------------+----------------------+------------------------------+\n"
            docker ps -a --format "{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | awk '{printf "| %-18s | %-28s | %-20s | %-28s |\n", $1, $2, $3, $4}'
            printf "+--------------------+------------------------------+----------------------+------------------------------+\n"
        )
    else
        echo "Information for container $1:"
        docker inspect "$1"
    fi
}

# Function to get Nginx information
get_nginx_info() {
    echo "Server Domain                 Proxy                          Configuration File"
    echo "+-----------------------------+------------------------------+---------------------------+"
    echo "| Domain                      | Proxy                        | Configuration File        |"
    echo "+-----------------------------+------------------------------+---------------------------+"

    for conf_file in /etc/nginx/sites-enabled/* /etc/nginx/conf.d/*; do
        if [[ -f "$conf_file" ]]; then
            domains=$(grep -oP '(?<=server_name\s)[^;]+' "$conf_file" | xargs)
            proxies=$(grep -oP '(?<=proxy_pass\s)[^;]+' "$conf_file" | xargs)
            for domain in $domains; do
                for proxy in $proxies; do
                    printf "| %-27s | %-28s | %-25s |\n" "$domain" "$proxy" "$conf_file"
                done
            done
        fi
    done
    echo "+-----------------------------+------------------------------+---------------------------+"
}

# Function to get user information
get_user_info() {
    if [ -z "$1" ]; then
        echo "Regular users and last login times:"
        (
            printf "+-----------------+----------------+----------+-----------------+\n"
            printf "| User            | Date           | Time     | Host            |\n"
            printf "+-----------------+----------------+----------+-----------------+\n"
            cut -d: -f1,3 /etc/passwd | awk -F: '$2 >= 1000 && $2 != 65534 {print $1}' | while read -r user; do
                last_login=$(last "$user" -1 2>/dev/null | awk 'NR==1 {print $4, $5, $3}')
                if [ -n "$last_login" ]; then
                    printf "| %-15s | %-14s | %-8s | %-15s |\n" "$user" $(echo "$last_login" | awk '{print $1, $2, $3}')
                else
                    printf "| %-15s | %-14s | %-8s | %-15s |\n" "$user" "Never logged in" "" ""
                fi
            done
            printf "+-----------------+----------------+----------+-----------------+\n"
        )
    else
        echo "Information for user $1:"
        if id "$1" >/dev/null 2>&1; then
            if [ "$(id -u "$1")" -ge 1000 ] && [ "$(id -u "$1")" -ne 65534 ]; then
                id "$1"
                echo "Last login:"
                last "$1" -1 | head -n 1
                echo "Groups:"
                id -Gn "$1" | tr ' ' '\n' | awk '{print "- " $1}'
            else
                echo "This is a system user, not a regular user."
            fi
        else
            echo "User $1 does not exist."
        fi
    fi
}


# Function to display system logs from a given date range
get_time_range_info() {
    if [ -z "$1" ]; then
        echo "Please provide a start date (YYYY-MM-DD)."
        return 1
    fi

    start_date=$(date -d "$1" +%Y-%m-%d 2>/dev/null)
    if [ -z "$start_date" ]; then
        echo "Invalid start date: $1"
        return 1
    fi

    if [ -n "$2" ]; then
        end_date=$(date -d "$2" +%Y-%m-%d 2>/dev/null)
        if [ -z "$end_date" ]; then
            echo "Invalid end date: $2"
            return 1
        fi
    else
        end_date=$(date +%Y-%m-%d)
    fi

    echo "Displaying system logs from $start_date 00:00:00 to $end_date 23:59:59:"
    (
        printf "+---------------------+---------------------+--------------------------------------------+\n"
        printf "| Date                | Time                | Message                                    |\n"
        printf "+---------------------+---------------------+--------------------------------------------+\n"
        journalctl --since="$start_date 00:00:00" --until="$end_date 23:59:59" | while read -r line; do
            # Extract date, time, and message
            log_date=$(echo "$line" | awk '{print $1}')
            log_time=$(echo "$line" | awk '{print $2}')
            message=$(echo "$line" | cut -d' ' -f3-)

            # Format and print the log entry
            printf "| %-19s | %-19s | %-40s |\n" "$log_date" "$log_time" "$message"
        done
        printf "+---------------------+---------------------+--------------------------------------------+\n"
    )
}


# Main script logic
case "$1" in
    -p|--port)
        get_port_info "$2"
        ;;
    -d|--docker)
        get_docker_info "$2"
        ;;
    -n|--nginx)
        get_nginx_info "$2"
        ;;
    -u|--users)
        get_user_info "$2"
        ;;
    -t|--time)
        get_time_range_info "$2" "$3"
        ;;
    -h|--help)
        display_help
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        exit 1
        ;;
esac
