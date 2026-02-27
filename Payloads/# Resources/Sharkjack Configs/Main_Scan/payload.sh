# #!/bin/bash
# Author: KC99 / Language: Bash
# Description: Personal payload built off "Sample Nmap Payload for Shark Jack"
# ======================= Start-Code =======================
# Payload includes: 
# Files: -------------
# 0) ifconfig - File: ifconfig.txt
# 0) route gateway - File: route.txt
# 0) internet test: - File: ping.txt
#
# nmap scans:
# arp scan on subnet 
# port scan & OS on discovered host - File: port.txt 
# -A scan on gateway - File: gate.txt
#
#
# LED feedback: ------------- 
# 0) discovered host - LED feedback
#
#
# LED Indicators:
# - R = Red
# - Y = Yellow
# - B = Blue
# - C = Cyan
# - W = White
# - G = Green
#
# nmap options: 
# -O = OS detection
# -A = Enable OS detection, version detection, script scanning, and traceroute
# -T[0-5] = Set timing template (higher is faster)
# -g[no.] = set source port 
# -sP = ping scan 
# 
# loot includes:
# ping.txt
# arp.txt
# gate.txt
# port.txt
# route.txt
# ifconfig


# Defining directories
LOOT_DIR=/root/loot/nmap/802.11 # Directory for storing scan results
SCAN_DIR=/etc/shark/nmap/802.11 # Directory for temporary scan files
# The scan-count file is used for tracking the number of scans performed or for initialization purposes.
SCAN_FILE=$SCAN_DIR/scan-count  # Define the path for the temporary scan file


# Function to clean up and halt the system after scan completion
function finish() {
    LED W FAST  # Set LED to indicate finishing
    sleep 3 # time to see LED
    kill $1 &> /dev/null # Kill Nmap process
    sync # Sync filesystem
    # Set LED to indicate finish
    LED FINISH
    sleep 3 # time to see LED
    halt # Halt system
}



# Function to set up environment and find subnet
function setup() {
    LED R SOLID # Set LED to indicate ready
    mkdir -p $LOOT_DIR &> /dev/null # Create loot directory if it doesn't exist
    mkdir -p $SCAN_DIR &> /dev/null # Create temporary scan directory if it doesn't exist
    if [ ! -f $SCAN_FILE ]; then # Check if the scan-count file exists
        touch $SCAN_FILE && echo 0 > $SCAN_FILE # If the file doesn't exist, create it and initialize its content to 0
    fi 
    # Find IP address and subnet using DHCP client
    NETMODE DHCP_CLIENT # sets netmode to DHCP
    ifconfig eth0 down
    ifconfig eth0 hw ether 40:92:1A:00:be:ef # (40:92:1A) vendor: apple
    ifconfig eth0 up
    while [ -z "$SUBNET" ]; do
        sleep 3 && find_subnet # sleep needed for mac spoof
    done

    # Discover gateway 
    DEFAULT_GATEWAY=$(ip route | awk '/default/ { print $3 }')
    echo "Default Gateway: $DEFAULT_GATEWAY" > $LOOT_DIR/route$SCAN_M.txt &>/dev/null &
    sleep 2
}




# Function to find subnet based on eth0 interface IP address
function find_subnet() {
    SUBNET=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" | sed 's/\.[0-9]*\//\.0\//')
}




# Main function to run the payload
function run() {
    setup # Run setup function
    # file numbering
    SCAN_N=$(cat $SCAN_FILE) 
    SCAN_M=$(( $SCAN_N + 1 ))
    ifconfig > $LOOT_DIR/ifconfig.txt # Output ifconfig to file
    sleep 2 

    # Start ARP scan
    nmap -sP --host-timeout 30s --max-retries 3 -T4 $SUBNET -oN $LOOT_DIR/arp$SCAN_M.txt &>/dev/null &
    arppid=$!
    wait $arppid # Wait for ARP scan to complete
    sleep 1 

    # Remove gateway IP from the arp.txt file
    grep -v "$DEFAULT_GATEWAY" $LOOT_DIR/arp$SCAN_M.txt > $LOOT_DIR/arp_temp.txt
    mv $LOOT_DIR/arp_temp.txt $LOOT_DIR/arp$SCAN_M.txt
    sleep 3 

    # shows user how many host there are
    num_hosts=$(grep -c "Nmap scan report" $LOOT_DIR/arp$SCAN_M.txt) # Count discovered hosts
    # Change LED color based on the number of discovered hosts
    if [ $num_hosts -gt 29 ]; then # Blue LED for over 30 & over hosts
        LED B SOLID 
    elif [ $num_hosts -gt 24 ]; then # Cyan LED for 25-29hosts (high 20 & over)
        LED C SOLID 
    elif [ $num_hosts -gt 19 ]; then # Green LED for 20-24 hosts (low 20)
        LED G SOLID 
    elif [ $num_hosts -gt 14 ]; then # White LED for 15-19 hosts (high 10)
        LED W SOLID 
    elif [ $num_hosts -gt 9 ]; then # Yellow LED for 10-14 hosts (low 10)
        LED Y SOLID 
    elif [ $num_hosts -gt 2 ]; then # Magenta LED for 3-9 hosts (high 0)
        LED M SOLID 
    elif [ $num_hosts -lt 3 ]; then # Red LED for 2 hosts (only me and AP) (low 0)
        LED R SOLID
    fi
    sleep 3 # time to see LED
    LED W SINGLE # cleaning LED
    sleep 2 # time to see LED

    # Start port scan on discovered hosts
    LED Y FAST # Set LED to indicate port scan
    # Determine what scans to preform based on the number of discovered hosts
    if [ $num_hosts -gt 49 ]; then # Skip port scan if over 49 hosts
        LED W SINGLE # Skip port scan
    elif [ $num_hosts -gt 29 ]; then # limited port scan if over 29 hosts
        LED Y FAST # LED indicator for port scanning
        nmap -p 20,21,22,23,25,53,80,443,110,119,124,143,161,194 -T4 -g 403 -oN $LOOT_DIR/port$SCAN_M.txt $(awk '/^Nmap scan report for/{print $NF}' $LOOT_DIR/arp$SCAN_M.txt) &>/dev/null &
        wait $!
    elif [ $num_hosts -gt 24 ]; then # Conduct port scan for ports if 25-29 hosts
        LED Y FAST # LED indicator for port scanning
        nmap -T4 -g 403 -oN $LOOT_DIR/port$SCAN_M.txt $(awk '/^Nmap scan report for/{print $NF}' $LOOT_DIR/arp$SCAN_M.txt) &>/dev/null &
        wait $!
    elif [ $num_hosts -lt 25 ]; then # Continue port scan with -O if less than 25 hosts
        LED Y FAST # LED indicator for port scanning
        nmap -T4 -O -g 403 -oN $LOOT_DIR/port$SCAN_M.txt $(awk '/^Nmap scan report for/{print $NF}' $LOOT_DIR/arp$SCAN_M.txt) &>/dev/null &
        wait $!
    else
        LED W SINGLE # Skip port scan
    fi
    sleep 3

    # starting gateway scan
    LED M FAST # Set LED to indicate gatway scan
    nmap -A $DEFAULT_GATEWAY -oN $LOOT_DIR/gate$SCAN_M.txt &>/dev/null &
    gatepid=$!
    # Wait for -A scan to complete
    wait $gatepid
    sleep 3

    # Test for internet connectivity by pinging Google DNS
    LED B FAST # Set LED to indicate ping 8.8.8.8
    ping -c 8 8.8.8.8 > $LOOT_DIR/ping$SCAN_M.txt &>/dev/null &
    pingpid=$! 
    wait $pingpid # Wait for ping to complete
    sleep 3 # Wait time before external ip test
    # Test for external ip
    curl ifconfig.me > $LOOT_DIR/external$SCAN_M.txt &>/dev/null &
    expid=$!  
    wait $expid # Wait for info to complete
    sleep 3

    # Finish and halt after completing all scans
    finish $gatepid
}

# Run payload
run &
