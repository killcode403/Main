import subprocess
import time

# Colors for text formatting
class bcolors:
    HEADER = '\033[95m'  # Header color
    OKBLUE = '\033[94m'  # Blue color
    OKGREEN = '\033[92m'  # Green color
    WARNING = '\033[93m'  # Warning color
    FAIL = '\033[91m'  # Fail color
    ENDC = '\033[0m'  # End color
    BOLD = '\033[1m'  # Bold text
    UNDERLINE = '\033[4m'  # Underline text
    ORANGE = '\033[33m'  # Orange color
    LIGHT_PURPLE = '\033[94m'  # Light Purple color
    YELLOW = '\033[38;5;190m'  # Yellow color (Color 190)

def list_wireless_interfaces():
    # Function to list available wireless interfaces
    print(f"{bcolors.OKBLUE}Available wireless interfaces:{bcolors.ENDC}")
    subprocess.run("iwconfig | grep 'wlan\|mode'", shell=True)  # Run iwconfig command to list wireless interfaces
    print("-------------------------------------")

def start_monitor_mode():
    # Function to start monitor mode setup
    print(f"{bcolors.ORANGE}Starting monitor mode setup...{bcolors.ENDC}")
    
    wifi_interface = input("Enter the interface name (e.g., wlan0): ")
    # Get user input for the wireless interface name
    
    print(f"{bcolors.ORANGE}Killing processes...{bcolors.ENDC}")
    monitor_command = f'ifconfig {wifi_interface} down && airmon-ng check kill && iwconfig {wifi_interface} mode monitor'
    # Command to set up monitor mode for the specified interface

    print(f"{bcolors.OKGREEN}Setting up monitor mode for {wifi_interface}...{bcolors.ENDC}")
    # Print message indicating the setup process has started
    time.sleep(2)  # Wait for 2 seconds

    # Execute command and check for errors
    result = subprocess.run(monitor_command, shell=True)
    if result.returncode != 0:
        print(f"{bcolors.FAIL}Error setting up monitor mode. Please check your input and try again.{bcolors.ENDC}")
        return

    print(f"{bcolors.OKGREEN}Monitor mode setup complete!{bcolors.ENDC}")
    # Print message indicating the setup process is complete
    time.sleep(2)  # Wait for 2 seconds
    print("-------------------------------------")
    list_wireless_interfaces()  # List wireless interfaces after setting up monitor mode
    time.sleep(2)  # Wait for 2 seconds

def stop_monitor_mode():
    # Function to stop monitor mode
    print(f"{bcolors.WARNING}Stopping monitor mode...{bcolors.ENDC}")

    stop_interface = input("Enter the interface name (e.g., wlan0 or wlan0mon): ")
    # Get user input for the wireless interface name to stop monitor mode

    stop_command = f'airmon-ng stop {stop_interface}'
    # Command to stop monitor mode for the specified interface

    print(f"{bcolors.WARNING}Stopping monitor mode for {stop_interface}...{bcolors.ENDC}")
    # Print message indicating the process of stopping monitor mode has started
    time.sleep(2)  # Wait for 2 seconds

    # Execute command and check for errors
    result = subprocess.run(stop_command, shell=True)
    if result.returncode != 0:
        print(f"{bcolors.FAIL}Error stopping monitor mode. Please check your input and try again.{bcolors.ENDC}")
        return

    list_wireless_interfaces()  # List wireless interfaces again before stopping monitor mode

    print(f"{bcolors.OKGREEN}Stopped monitor mode for {stop_interface}{bcolors.ENDC}")
    # Print message indicating that monitor mode has been stopped for the specified interface
    time.sleep(2)  # Wait for 2 seconds
    print("-------------------------------------")

    # Command to check NetworkManager status and highlight it in yellow color
    status_command = "systemctl status NetworkManager | grep Active | sed 's/\\(.*\\)/\\x1b[38;5;190m\\1\\x1b[0m/'"

    # Print message indicating that NetworkManager status is being checked
    print(f"{bcolors.OKBLUE}Checking NetworkManager status...{bcolors.ENDC}")

    # Run the command using subprocess.run()
    status_result = subprocess.run(status_command, shell=True, capture_output=True, text=True)

    # Print the result
    print(status_result.stdout.strip())

    restart_network_manager = input("Do you wish to restart NetworkManager? (Y/N): ")
    if restart_network_manager.lower() == 'y':
        print(f"{bcolors.ORANGE}Restarting NetworkManager...{bcolors.ENDC}")
        # Print message indicating that NetworkManager is being restarted
        time.sleep(2)  # Wait for 2 seconds
        subprocess.run('service NetworkManager restart', shell=True)  # Restart NetworkManager service
        print("-------------------------------------")
        
        status_result = subprocess.run(status_command, shell=True, capture_output=True, text=True)
        print("Checking NetworkManager status...")
        # Print message indicating that NetworkManager status is being checked
        time.sleep(2)  # Wait for 2 seconds
        print(status_result.stdout.strip())
        print("-------------------------------------")

def main():
    list_wireless_interfaces()  # List wireless interfaces before the first question
    choice = input(f"{bcolors.BOLD}Do you wish to start or end monitor mode? (S/E): {bcolors.ENDC}")
    # Ask the user if they want to start or end monitor mode
    if choice.lower() == 's':
        start_monitor_mode()  # Call the function to start monitor mode
    elif choice.lower() == 'e':
        stop_monitor_mode()  # Call the function to stop monitor mode
    else:
        print(f"{bcolors.FAIL}Invalid choice. Exiting...{bcolors.ENDC}")
        # Print message for invalid choice
    # End code confirmation
    input(f"{bcolors.BOLD}End Code? Press Enter to exit.{bcolors.ENDC}")

if __name__ == "__main__":
    main()
