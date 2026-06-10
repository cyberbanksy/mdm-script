# MDM-bypass Script

This is a modified version of the MDM-bypass script designed for Apple Silicon Macs.

## Prerequisites:

1. The device can't be bios-locked.
2. M-Series only (Apple Silicon).
3. Freshly installed MacOS Ventura/Sonoma.

## Installation and Usage:

1. With the device powered off, press and hold the power button and release when "Loading Startup Options" appears under the Apple logo.
2. Connect to WiFi and Activate the Mac.
3. Open Safari and go back to this repo: https://github.com/cyberbanksy/mdm-script
4. Copy this command:

   ```bash
   curl https://raw.githubusercontent.com/cyberbanksy/mdm-script/main/MDM-bypass.sh -o MDM-bypass.sh && chmod +x ./MDM-bypass.sh && ./MDM-bypass.sh
   ```

5. Quit Safari. (At the top left of the screen, next to the Apple logo, click Safari --> Quit Safari)
6. Open the Terminal (Applications --> Utilities --> Terminal).
7. Paste the command in the terminal (Command + V) and press enter.
8. Type 1 and press Enter.
9. Type your full name or leave it empty and press enter.
10. Type your username or leave it empty and press enter. (Default username is Apple)
11. Type your password or leave it empty and press enter. (Default password is 1234)
12. Wait for it to complete and reboot. (Type "reboot" and press enter)
13. Profit.

## Troubleshooting:

1. Delete the drive.
2. Activate the Mac.
3. Reinstall macOS from recovery.
4. At the "Select Your Country or Region" screen, press and hold the power button until the screen goes black to shut down.
5. Follow the installation instructions.

## Important Safety Note:

This script modifies system files and should only be used on devices you legally own or have explicit permission to modify. It's designed for bypassing institutional MDM (Mobile Device Management) enrollment, which may violate terms of service of some organizations.

## About This Fork:

This repository is a fork of the original MDM-bypass project by eudy97 and includes fixes and improvements to make it compatible with modern Apple Silicon Macs.
