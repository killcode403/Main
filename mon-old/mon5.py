import os
import subprocess
import time

# Colors for text formatting
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def list_network_interfaces():
    print(f"{bcolors.OKBLUE}Available network interfaces:{bcolors.ENDC}")
    os.system('ifconfig')
    print("-------------------------------------")

def start_monitor_mode():
    print(f"{bcolors.OKBLUE}Starting monitor mode setup...{bcolors.ENDC}")

    wifi_interface = input("Enter the interface name (e.g., wlan0): ")
    monitor_command = f'ifconfig {wifi_interface} down && airmon-ng check kill {wifi_interface} && airmon-ng start {wifi_interface} 1'
    print(f"{bcolors.OKGREEN}Setting up monitor mode for {wifi_interface}...{bcolors.ENDC}")
    time.sleep(2)

    # Execute command and check for errors
    result = os.system(monitor_command)
    if result != 0:
        print(f"{bcolors.FAIL}Error setting up monitor mode. Please check your input and try again.{bcolors.ENDC}")
        return

    print(f"{bcolors.OKGREEN}Monitor mode setup complete!{bcolors.ENDC}")
    time.sleep(2)
    print("-------------------------------------")
    os.system('iwconfig')
    time.sleep(2)

def stop_monitor_mode():
    print(f"{bcolors.WARNING}Stopping monitor mode...{bcolors.ENDC}")

    stop_interface = input("Enter the interface name (e.g., wlan0 or wlan0mon): ")
    stop_command = f'airmon-ng stop {stop_interface}'
    print(f"{bcolors.WARNING}Stopping monitor mode for {stop_interface}...{bcolors.ENDC}")
    time.sleep(2)

    # Execute command and check for errors
    result = os.system(stop_command)
    if result != 0:
        print(f"{bcolors.FAIL}Error stopping monitor mode. Please check your input and try again.{bcolors.ENDC}")
        return

    print(f"{bcolors.OKGREEN}Stopped monitor mode for {stop_interface}{bcolors.ENDC}")
    time.sleep(2)
    print("-------------------------------------")

    status_command = "systemctl status NetworkManager | grep '● NetworkManager\|Active\|Docs\|Main PID\|Tasks\|Memory\|CPU'"
    print(f"{bcolors.OKBLUE}Checking NetworkManager status...{bcolors.ENDC}")
    time.sleep(2)
    status_result = subprocess.run(status_command, shell=True, capture_output=True, text=True)
    print(status_result.stdout.strip())

    restart_network_manager = input("Do you wish to restart NetworkManager? (Y/N): ")
    if restart_network_manager.lower() == 'y':
        print(f"{bcolors.OKBLUE}Restarting NetworkManager...{bcolors.ENDC}")
        time.sleep(2)
        os.system('service NetworkManager restart')
        print("-------------------------------------")

def main():
    list_network_interfaces()

    choice = input(f"{bcolors.BOLD}Do you wish to start or stop monitor mode? (Y/N): {bcolors.ENDC}")
    if choice.lower() == 'y':
        start_monitor_mode()
    elif choice.lower() == 'n':
        stop_monitor_mode()
    else:
        print(f"{bcolors.FAIL}Invalid choice. Exiting...{bcolors.ENDC}")

    # End code confirmation
    input(f"{bcolors.BOLD}End Code? Press Enter to exit.{bcolors.ENDC}")

if __name__ == "__main__":
    main()
