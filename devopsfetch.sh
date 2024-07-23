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
            printf "%-10s %-10s %-20s %-20s\n" "Protocol" "PORT" "State" "Program Name"
            lsof -i -P -n | grep LISTEN | awk '{split($9,a,":"); printf "%-10s %-10s %-20s %-20s\n", $1, a[length(a)], $10, $2 "/" $1}'
            lsof -i -P -n | grep -v LISTEN | awk '{split($9,a,":"); printf "%-10s %-10s %-20s %-20s\n", $1, a[length(a)], $10, $2 "/" $1}'
        ) | format_table
    else
        echo "Information for port $1:"
        (
            printf "%-10s %-10s %-20s %-20s\n" "Protocol" "PORT" "State" "Program Name"
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

                printf "%-10s %-10s %-20s %-20s\n" "$protocol" "$port" "$state" "$program"
            done
        ) | format_table
    fi
}

# Function to get Docker information
get_docker_info() {
    if [ -z "$1" ]; then
        echo "Docker images:"
        (
            printf "%-30s %-20s %-20s %-15s\n" "Repository" "Tag" "ID" "Size"
            docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | 
            awk '{printf "%-30s %-20s %-20s %-15s\n", $1, $2, $3, $4}'
        ) | format_table
        echo -e "\nDocker containers:"
        (
            printf "%-20s %-30s %-20s %-30s\n" "Names" "Image" "Status" "Ports"
            docker ps -a --format "{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | 
            awk '{printf "%-20s %-30s %-20s %-30s\n", $1, $2, $3, $4}'
        ) | format_table
    else
        echo "Information for container $1:"
        docker inspect "$1"
    fi
}

# Function to get Nginx information
get_nginx_info() {
    if [ -z "$1" ]; then
        echo "Nginx domains and ports:"
        (
            printf "%-30s %-10s\n" "Domain" "Port"
            grep -r -E 'server_name|listen' /etc/nginx/sites-enabled/ | awk '
            {
                file = $1; gsub(":$", "", file)
                if ($2 == "server_name") {
                    domain = $3; gsub(";", "", domain)
                    port = "80"  # Default port if listen is not specified
                }
                if ($2 == "listen") {
                    port = $3; gsub(";", "", port)
                }
                if (domain != "" && port != "") {
                    printf "%-30s %-10s\n", domain, port
                    domain = ""
                    port = ""
                }
            }'
        ) | format_table
    else
        echo "Configuration for domain $1:"
        grep -r -A 20 "server_name $1" /etc/nginx/sites-enabled/ || echo "No server found for domain $1."
    fi
}

# Function to get user information
get_user_info() {
    if [ -z "$1" ]; then
        echo "Regular users and last login times:"
        (
            printf "%-15s %-12s %-8s %-15s\n" "User" "Date" "Time" "Host"
            cut -d: -f1,3 /etc/passwd | awk -F: '$2 >= 1000 && $2 != 65534 {print $1}' | while read -r user; do
                last_login=$(last "$user" -1 2>/dev/null | awk 'NR==1 {print $4, $5, $3}')
                if [ -n "$last_login" ]; then
                    printf "%-15s %-12s %-8s %-15s\n" "$user" $(echo "$last_login" | awk '{print $1, $2, $3}')
                else
                    printf "%-15s %-12s %-8s %-15s\n" "$user" "Never logged in" "" ""
                fi
            done
        ) | format_table
    else
        echo "Information for user $1:"
        if id "$1" >/dev/null 2>&1; then
            if [ "$(id -u "$1")" -ge 1000 ] && [ "$(id -u "$1")" -ne 65534 ]; then
                id "$1"
                echo "Last login:"
                last "$1" -1 | head -n 1
            else
                echo "This is a system user, not a regular user."
            fi
        else
            echo "User $1 does not exist."
        fi
    fi
}

# Function to get time range information
get_time_range_info() {
    # Check if a start date is provided
    if [ -z "$1" ]; then
        echo "Please provide a start date (YYYY-MM-DD)."
        return 1
    fi

    # Set the start date
    start_date=$(date -d "$1" +%Y-%m-%d 2>/dev/null)
    if [ -z "$start_date" ]; then
        echo "Invalid start date: $1"
        return 1
    fi
    
    # Default end date to today if not provided
    if [ -n "$2" ]; then
        end_date=$(date -d "$2" +%Y-%m-%d 2>/dev/null)
        if [ -z "$end_date" ]; then
            echo "Invalid end date: $2"
            return 1
        fi
    else
        end_date=$(date +%Y-%m-%d)
    fi
    
    echo "Activities from $start_date to $end_date:"

    # Fetch activities within the date range
    activities=$(last -F | awk -v start="$start_date" -v end="$end_date" '
    BEGIN {
        FS=" "; OFS="\t"
        month_map["Jan"]="01"; month_map["Feb"]="02"; month_map["Mar"]="03"; month_map["Apr"]="04"; month_map["May"]="05"; month_map["Jun"]="06";
        month_map["Jul"]="07"; month_map["Aug"]="08"; month_map["Sep"]="09"; month_map["Oct"]="10"; month_map["Nov"]="11"; month_map["Dec"]="12";
        count = 0
    }
    {
        # Construct log date in YYYY-MM-DD format
        log_date = $7 "-" month_map[$5] "-" $6

        # Compare log date with start and end dates
        if (log_date >= start && log_date <= end) {
            printf "%-15s %-20s %-20s %-20s %-20s\n", $1, $3, $4, $5 " " $6 " " $7, $8
            count++
        }
    }
    END { 
        print count > "/dev/stderr"
        if (count == 0) {
            exit 1
        }
    }')

    # Capture activity count from stderr
    activity_count=$(echo "$activities" | tail -n 1)

    # Remove the last line which contains the count
    activities=$(echo "$activities" | sed '$d')

    if [ -z "$activity_count" ] || [ "$activity_count" -eq 0 ]; then
        echo "No activities found in the specified time range."
    else
        echo "Activity count: $activity_count"
        echo "$activities"
    fi
}

# Function to format output as a table
format_table() {
    column -t -s $'\t'
}

# Main function to handle command-line arguments
main() {
    log_activity "DevOpsFetch executed with arguments: $*"

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
}

# Call the main function with all script arguments
main "$@"
