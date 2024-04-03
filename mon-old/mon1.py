import os
import subprocess
import time

def clear_screen():
    os.system('clear' if os.name == 'posix' else 'cls')

def start_monitor_mode():
    clear_screen()
    print("Starting...")
    time.sleep(3)
    clear_screen()

    wifi_interface = input("Enter the interface name (e.g., wlan0): ")
    monitor_command = f'ifconfig {wifi_interface} down && airmon-ng check kill {wifi_interface} && airmon-ng start {wifi_interface} 1'
    os.system(monitor_command)

    print("Monitor mode setup complete!")
    time.sleep(2)
    clear_screen()
    os.system('iwconfig')

def stop_monitor_mode():
    clear_screen()
    stop_interface = input("Enter the interface name (e.g., wlan0 or wlan0mon): ")
    stop_command = f'airmon-ng stop {stop_interface}'
    os.system(stop_command)

    print("Stopped monitor mode for", stop_interface)
    time.sleep(2)
    clear_screen()

    restart_network_manager = input("Do you wish to restart NetworkManager? (Y/N): ")
    if restart_network_manager.lower() == 'y':
        clear_screen()
        print("Restarting NetworkManager...")
        time.sleep(2)
        os.system('service NetworkManager restart')
        clear_screen()

def main():
    clear_screen()
    choice = input("Do you wish to start or stop monitor mode? (1 for start, 2 for stop): ")
    if choice == '1':
        start_monitor_mode()
    elif choice == '2':
        stop_monitor_mode()
    else:
        print("Invalid choice. Exiting...")

if __name__ == "__main__":
    main()
