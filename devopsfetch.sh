# #!/bin/bash

# # Help function to display usage instructions
# show_help() {
#     echo "Usage: $0 [option] [argument]"
#     echo "Options:"
#     echo "  -p, --port [port_number]     Display all active ports or detailed info about a specific port."
#     echo "  -d, --docker [container]     List all Docker images and containers or detailed info about a specific container."
#     echo "  -n, --nginx [domain]         Display Nginx domains or detailed info about a specific domain."
#     echo "  -u, --users [username]       List all users or detailed info about a specific user."
#     echo "  -t, --time [time_range]      Display activities within a specified time range."
#     echo "  -h, --help                   Show this help message and exit."
# }

# # Logging function
# log_message() {
#     echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/devopsfetch.log
# }

# # Get all active ports
# get_active_ports() {
#     log_message "Fetching active ports"
#     ss -tuln | awk 'NR>1 {printf "%-7s %-30s %-30s\n", $1, $4, $5}'
# }

# # Get detailed information for a specific port
# get_port_info() {
#     log_message "Fetching info for port $1"
#     ss -tuln | grep ":$1 " | awk '{printf "%-7s %-30s %-30s\n", $1, $4, $5}'
# }

# # List all Docker images
# get_docker_images() {
#     log_message "Listing Docker images"
#     docker images
# }

# # Get detailed information about a specific Docker container
# get_docker_container_info() {
#     log_message "Fetching Docker container info for $1"
#     docker inspect "$1"
# }

# # List all Nginx domains and their ports
# get_nginx_domains() {
#     log_message "Fetching Nginx domains"
#     grep -r 'server_name' /etc/nginx/sites-enabled/
# }

# # Get detailed information for a specific Nginx domain
# get_nginx_domain_info() {
#     log_message "Fetching Nginx domain info for $1"
#     cat "/etc/nginx/sites-available/$1"
# }

# # List all users and their last login times
# get_users() {
#     log_message "Listing users and last login times"
#     last | awk '{printf "%-15s %-20s %-20s\n", $1, $3, $4}'
# }

# # Get detailed information about a specific user
# get_user_info() {
#     log_message "Fetching user info for $1"
#     getent passwd "$1"
#     last -F "$1"
# }

# # Placeholder function for displaying activities within a specified time range
# get_time_range_activities() {
#     log_message "Fetching activities for time range: $1"
#     echo "Displaying activities for the time range: $1"
#     # Add actual implementation for time range activities here
# }

# # Main function to parse arguments and call appropriate functions
# main() {
#     case "$1" in
#         -p|--port)
#             if [ -z "$2" ]; then
#                 get_active_ports
#             else
#                 get_port_info "$2"
#             fi
#             ;;
#         -d|--docker)
#             if [ -z "$2" ]; then
#                 get_docker_images
#             else
#                 get_docker_container_info "$2"
#             fi
#             ;;
#         -n|--nginx)
#             if [ -z "$2" ]; then
#                 get_nginx_domains
#             else
#                 get_nginx_domain_info "$2"
#             fi
#             ;;
#         -u|--users)
#             if [ -z "$2" ]; then
#                 get_users
#             else
#                 get_user_info "$2"
#             fi
#             ;;
#         -t|--time)
#             get_time_range_activities "$2"
#             ;;
#         -h|--help)
#             show_help
#             ;;
#         *)
#             echo "Invalid option: $1"
#             show_help
#             ;;
#     esac
# }

# # Call the main function with all script arguments
# main "$@"



#!/bin/bash

# Help function to display usage instructions
show_help() {
    echo "Usage: $0 [option] [argument]"
    echo "Options:"
    echo "  -p, --port [port_number]     Display all active ports or detailed info about a specific port."
    echo "  -d, --docker [container]     List all Docker images and containers or detailed info about a specific container."
    echo "  -n, --nginx [domain]         Display Nginx domains or detailed info about a specific domain."
    echo "  -u, --users [username]       List all users or detailed info about a specific user."
    echo "  -t, --time [start_time] [end_time]  Display activities within a specified time range."
    echo "  -h, --help                   Show this help message and exit."
}

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/devopsfetch.log
}

# Get all active ports
get_active_ports() {
    log_message "Fetching active ports"
    echo -e "PROTO\tLOCAL ADDRESS\t\t\tFOREIGN ADDRESS\t\t\tSTATE"
    ss -tuln | awk 'NR>1 {printf "%-7s %-30s %-30s %-15s\n", $1, $4, $5, $6}'
}

# Get detailed information for a specific port
get_port_info() {
    log_message "Fetching info for port $1"
    echo -e "PROTO\tLOCAL ADDRESS\t\t\tFOREIGN ADDRESS\t\t\tSTATE"
    ss -tuln | grep ":$1 " | awk '{printf "%-7s %-30s %-30s %-15s\n", $1, $4, $5, $6}'
}

# List all Docker images
# get_docker_images() {
#     log_message "Listing Docker images"
#     docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ImageID}}\t{{.CreatedAt}}\t{{.Size}}"
# }

# Get detailed information about a specific Docker container
get_docker_container_info() {
    log_message "Fetching Docker container info for $1"
    docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
    docker inspect "$1"
}
get_docker_images() {
    log_message "Listing Docker images info"
    docker images #--format "table {{.Repository}}\t{{.Tag}}\t{{.ImageID}}\t{{.CreatedAt}}\t{{.Size}}"
    
    
}
# List all Nginx domains and their ports
get_nginx_domains() {
    log_message "Fetching Nginx domains"
    echo -e "FILE\t\tSERVER NAME"
    grep -r 'server_name' /etc/nginx/sites-enabled/ | awk -F: '{print $1 "\t" $2}'
}

# Get detailed information for a specific Nginx domain
get_nginx_domain_info() {
    log_message "Fetching Nginx domain info for $1"
    cat "/etc/nginx/sites-available/$1"
}

# List all users and their last login times
get_users() {
    log_message "Listing users and last login times"
    echo -e "USERNAME\t\tFROM\t\t\tLOGIN TIME\t\tDURATION\t\tIP ADDRESS"
    last | awk '{printf "%-15s %-20s %-20s %-20s %-20s\n", $1, $3, $4, $5, $7}'
}

# Get detailed information about a specific user
get_user_info() {
    log_message "Fetching user info for $1"
    getent passwd "$1"
    last -F "$1"
}

# Function to get activities within a specified time range
get_time_range_activities() {
    log_message "Fetching activities for time range: $1 to $2"

    # Convert dates to seconds since epoch for comparison
    start_date=$(date -d "$1" +%s)
    end_date=$(date -d "$2" +%s)

    # Check if start date is valid
    if [[ $? -ne 0 ]]; then
        echo "Invalid start date: $1"
        return 1
    fi

    # Check if end date is valid
    if [[ $? -ne 0 ]]; then
        echo "Invalid end date: $2"
        return 1
    fi

    # Ensure end_date is not before start_date
    if ((end_date < start_date)); then
        echo "End date must be after start date."
        return 1
    fi

    # Print activities within the time range
    echo -e "USERNAME\tFROM\tLOGIN TIME\tDURATION\tIP ADDRESS"
    last -F | awk -v start="$start_date" -v end="$end_date" '
    BEGIN {FS=" "; OFS="\t"}
    {
        log_date = mktime(substr($4,7,4)" "substr($4,1,3)" "substr($4,4,2)" "substr($5,1,2)" "substr($5,4,2)" "substr($5,7,2))
        if (log_date >= start && log_date <= end) {
            printf "%s\t%s\t%s %s\t%s\t%s\n", $1, $3, $4, $5, $6, $7
        }
    }'
}

# Main function to parse arguments and call appropriate functions
main() {
    case "$1" in
        -p|--port)
            if [ -z "$2" ]; then
                get_active_ports
            else
                get_port_info "$2"
            fi
            ;;
        -d|--docker)
            if [ -z "$2" ]; then
                get_docker_images
            else
                get_docker_container_info "$2"
            fi
            ;;
        -n|--nginx)
            if [ -z "$2" ]; then
                get_nginx_domains
            else
                get_nginx_domain_info "$2"
            fi
            ;;
        -u|--users)
            if [ -z "$2" ]; then
                get_users
            else
                get_user_info "$2"
            fi
            ;;
        -t|--time)
            if [ -z "$2" ]; then
                echo "Error: Time range is required"
                show_help
                exit 1
            else
                start_time=$2
                if [ -n "$3" ]; then
                    end_time=$3
                else
                    end_time=$(date '+%Y-%m-%d')
                fi
                get_time_range_activities "$start_time" "$end_time"
            fi
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Invalid option: $1"
            show_help
            ;;
    esac
}

# Call the main function with all script arguments
main "$@"
