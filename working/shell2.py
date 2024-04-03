# Note: code is incomplete and contains errors. this code of making is able to open multi tabs in a seprate window with qterminal with zsh
import subprocess
import time

# Define the commands to execute in each tab
commands = [
    "echo 'This is Tab 1'",
    "echo 'This is Tab 2'",
    "echo 'This is Tab 3'"
]

# Function to send keys to QTerminal
def send_keys(keys):
    subprocess.run(["xdotool", "key", "--clearmodifiers", keys])
    time.sleep(0.5)

# Launch QTerminal
qterminal_process = subprocess.Popen(["qterminal"])

# Wait for QTerminal to open
time.sleep(1)

# Send keys to open new tabs and execute commands
for i, cmd in enumerate(commands):
    if i > 0:
        send_keys("ctrl+shift+t")  # Send Ctrl+Shift+T to open a new tab
    send_keys(cmd + " && clear\n")  # Execute command in the new tab

# Keep the QTerminal window open
input("Press Enter to exit...")
