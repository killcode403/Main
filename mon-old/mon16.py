# Co-author: KC99 / Filename: NUL (python)
# Description: run to automate the setup of monitor mode in linux
# ======================= Start-Code =======================
import subprocess
import time

class bcolors: # Colors for text formatting
    # System colours
    WHITE = '\033[97m'  # White color | Used for standed info
    OKBLUE = '\033[94m'  # Blue color | Used for info or status
    WARNING = '\033[93m'  # Warning color | Used to show running processes
    OKGREEN = '\033[92m'  # Green color | Used when operation is completed
    FAIL = '\033[91m'  # Fail color | Used for error handling
    YELLOW = '\033[38;5;190m'  # Yellow color (Color 190) | Undefined  
    # System functions
    HEADER = '\033[95m'  # Header color
    ENDC = '\033[0m'  # End color | Undefined
    BOLD = '\033[1m'  # Bold text | Undefined
    UNDERLINE = '\033[4m'  # Underline text | Undefined
    



def list_wireless_interfaces(): # Function to list available interfaces
    # Notify user system is checking for interfaces | (highlight blue)
    print(f"{bcolors.OKBLUE}Listing available interfaces...{bcolors.ENDC}")
    # Defining the command to list available interfaces
    subprocess.run("iwconfig | grep 'Mode\|wlan'", shell=True)  # Run iwconfig command to list wireless interfaces
    print("-------------------------------------")




def start_monitor_mode(): # Function to start monitor mode setup
    # Notify user proccess is starting
    print(f"{bcolors.WHITE}Entering process:{bcolors.ENDC}")
    # Get user input for the wireless interface name
    wifi_interface = input("Enter the interface name (e.g., wlan0): ")
    
    # Notify user that system is finding and killing proccess that will interfere 
    print(f"{bcolors.WARNING}Finding processes...{bcolors.ENDC}")
    time.sleep(2)  # Wait for 2 seconds
    print(f"{bcolors.WARNING}Killing processes...{bcolors.ENDC}")
    
    # Defining the command to set up monitor mode for the specified interface
    monitor_command = f'ifconfig {wifi_interface} down && airmon-ng check kill && iwconfig {wifi_interface} mode monitor'
    time.sleep(2)  # Wait for 2 seconds
    # Execute command and check for errors
    result = subprocess.run(monitor_command, shell=True)
    if result.returncode != 0:
        print(f"{bcolors.FAIL}Error setting up monitor mode. Please check your input and try again.{bcolors.ENDC}")
        return
    
    # Print message indicating that NetworkManager status is being checked | (highlight blue)
    print(f"{bcolors.OKBLUE}Checking NetworkManager status...{bcolors.ENDC}")
    # Defining the command to check NetworkManager status | (highlight yellow)
    status_command = "systemctl status NetworkManager | grep Active | sed 's/\\(.*\\)/\\x1b[38;5;190m\\1\\x1b[0m/'"
    # Defining: Run command using subprocess.run()
    status_result = subprocess.run(status_command, shell=True, capture_output=True, text=True)
    # Print NetworkManager status result
    print(status_result.stdout.strip())
    time.sleep(2)  # Wait for 2 seconds
    
    # Print message indicating the setup process is complete
    print(f"{bcolors.OKGREEN}<{bcolors.ENDC}{bcolors.OKGREEN}Monitor mode setup complete{bcolors.ENDC}{bcolors.OKGREEN}>{bcolors.ENDC}")
    time.sleep(2)  # Wait for 2 seconds (needed delay to list)
    # List wireless interfaces after setting up monitor mode 
    list_wireless_interfaces()




def stop_monitor_mode(): # Function to stop monitor mode
    print(f"{bcolors.WHITE}Entering process:{bcolors.ENDC}")
    stop_interface = input("Enter the interface name (e.g., wlan0 or wlan0mon): ")

    # Notify user proccess is starting
    print(f"{bcolors.WARNING}Processing...{bcolors.ENDC}")
    time.sleep(3)  # Wait for 3 seconds
    # Define the command to stop monitor mode for the specified interface
    stop_command = f'ifconfig {stop_interface} down && iwconfig {stop_interface} mode managed'
    time.sleep(2)  # Wait for 2 seconds
    
    try:
        # Execute the stop command
        subprocess.run(stop_command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error occurred: {e}")
    
    # Print message indicating that monitor mode has been stopped for the specified interface
    print(f"{bcolors.OKGREEN}<{bcolors.ENDC}{bcolors.OKGREEN}Stopped monitor mode for {stop_interface}{bcolors.ENDC}{bcolors.OKGREEN}>{bcolors.ENDC}")
    
    time.sleep(2)  # Wait for 2 seconds (needed delay to list)
    # List wireless interfaces after setting up monitor mode 
    list_wireless_interfaces()
    
    # Define: command to check NetworkManager status and highlight it in yellow color
    status_command = "systemctl status NetworkManager | grep Active | sed 's/\\(.*\\)/\\x1b[38;5;190m\\1\\x1b[0m/'"
    # Define the to list nmcli radio
    nmcli_command = "nmcli r" 
    # Define: Run the command using subprocess.run()
    status_result = subprocess.run(status_command, shell=True, capture_output=True, text=True)
   
   
   
   
   
    # Print message indicating that NetworkManager status is being checked
    print(f"{bcolors.OKBLUE}Checking NetworkManager status...{bcolors.ENDC}")   
    # Print NetworkManager status result
    print(status_result.stdout.strip())
    
    
    # Define: command
    restart_network_manager = input("Do you wish to restart NetworkManager? (Y/N): ")
    if restart_network_manager.lower() == 'y':
       
        # Print message indicating that NetworkManager is being restarted
        print(f"{bcolors.WARNING}Restarting NetworkManager...{bcolors.ENDC}")
        # Execute the NetworkManager restart
        subprocess.run('systemctl restart NetworkManager', shell=True)  # Restart NetworkManager service
        
        
        print("-------------------------------------")        
        status_result = subprocess.run(status_command, shell=True, capture_output=True, text=True)
      
      
        # Notify user NetworkManager status is being checked
        print(f"{bcolors.OKBLUE}Checking NetworkManager status...{bcolors.ENDC}")
        
        time.sleep(1)  # Wait for 1 second
       
        # Print NetworkManager status result
        print(status_result.stdout.strip())
        print("-------------------------------------")
        nmcli_result = subprocess.run(['nmcli', 'r'], capture_output=True, text=True)
      
      
        if nmcli_result.returncode == 0:
            print(nmcli_result.stdout.strip())
        else:
            print("Error: Failed to retrieve NetworkManager status.")











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
