#!/bin/bash

# Check if running on Apple Silicon Mac
if [[ $(uname -m) != "arm64" ]]; then
    echo "This script is designed for Apple Silicon Macs only."
    echo "Exiting..."
    exit 1
fi

# Global constants
readonly DEFAULT_SYSTEM_VOLUME="Macintosh HD"
readonly DEFAULT_DATA_VOLUME="Macintosh HD - Data"

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Checks if a volume with the given name exists
checkVolumeExistence() {
    local volumeLabel="$*"
    diskutil info "$volumeLabel" >/dev/null 2>&1
}

# Returns the name of a volume with the given type
getVolumeName() {
    local volumeType="$1"

    # Getting the APFS Container Disk Identifier
    apfsContainer=$(diskutil list internal physical | grep 'Container' | awk -F'Container ' '{print $2}' | awk '{print $1}')
    # Getting the Volume Information
    volumeInfo=$(diskutil ap list "$apfsContainer" | grep -A 5 "($volumeType)")
    # Extracting the Volume Name from the Volume Information
    volumeNameLine=$(echo "$volumeInfo" | grep 'Name:')
    # Removing unnecessary characters to get the clean Volume Name
    volumeName=$(echo "$volumeNameLine" | cut -d':' -f2 | cut -d'(' -f1 | xargs)

    echo "$volumeName"
}

# Defines the path to a volume with the given default name and volume type
defineVolumePath() {
    local defaultVolume=$1
    local volumeType=$2

    if checkVolumeExistence "$defaultVolume"; then
        echo "/Volumes/$defaultVolume"
    else
        local volumeName
        volumeName="$(getVolumeName "$volumeType")"
        echo "/Volumes/$volumeName"
    fi
}

# Mounts a volume at the given path
mountVolume() {
    local volumePath=$1

    if [ ! -d "$volumePath" ]; then
        # Try mounting the volume with more specific commands
        if ! diskutil mount "$volumePath" 2>/dev/null; then
            # If mount fails, try to mount by disk identifier
            volumeName=$(basename "$volumePath")
            diskutil mount "$volumeName" 2>/dev/null
        fi
    fi
}

# Function to safely check and create user
createUserSafely() {
    local dscl_path="$1"
    local localUserDirPath="$2"
    local username="$3"
    local fullName="$4"
    local userPassword="$5"
    
    # Check if user already exists
    if dscl -f "$dscl_path" localhost -list "$localUserDirPath" UniqueID 2>/dev/null | grep -q "\<501\>"; then
        echo -e "${BLUE}User already exists${NC}"
        return 0
    fi
    
    # Create user with safety checks
    echo -e "${BLUE}Creating user: $username${NC}"
    
    # Create the user account
    if ! dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" 2>/dev/null; then
        echo -e "${RED}Failed to create user account${NC}"
        return 1
    fi
    
    # Set user properties
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UserShell "/bin/zsh" 2>/dev/null
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" RealName "$fullName" 2>/dev/null
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UniqueID "501" 2>/dev/null
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" PrimaryGroupID "20" 2>/dev/null
    
    # Create home directory
    mkdir -p "$dataVolumePath/Users/$username" 2>/dev/null
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" NFSHomeDirectory "/Users/$username" 2>/dev/null
    
    # Set password
    dscl -f "$dscl_path" localhost -passwd "$localUserDirPath/$username" "$userPassword" 2>/dev/null
    
    # Add to admin group
    dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username" 2>/dev/null
    
    echo -e "${GREEN}User created successfully${NC}"
    return 0
}

# Function to properly set up Apple Setup Done flag
setupAppleSetupDone() {
    echo -e "${BLUE}Setting up Apple Setup Done flag...${NC}"
    
    # Create the .AppleSetupDone file 
    local setupDonePath="$dataVolumePath/private/var/db/.AppleSetupDone"
    
    # Ensure the directory exists
    mkdir -p "$dataVolumePath/private/var/db" 2>/dev/null
    
    # Create the file with proper ownership and permissions
    if touch "$setupDonePath" 2>/dev/null; then
        echo -e "${GREEN}Apple Setup Done flag created successfully${NC}"
    else
        echo -e "${YELLOW}Warning: Could not create .AppleSetupDone flag${NC}"
        # Try alternative method
        if [ -d "$dataVolumePath/private/var/db" ]; then
            echo "1" > "$setupDonePath" 2>/dev/null && echo -e "${GREEN}Apple Setup Done flag created with data${NC}" || echo -e "${RED}Failed to create flag${NC}"
        fi
    fi
    
    # Also ensure proper flags and directories
    if [ -d "$dataVolumePath/private/var/db" ]; then
        touch "$dataVolumePath/private/var/db/.AppleSetupDone" 2>/dev/null
        chmod 644 "$dataVolumePath/private/var/db/.AppleSetupDone" 2>/dev/null
    fi
}

echo "MDM Bypass Script for Apple Silicon Macs"
echo "========================================"

PS3='Please enter your choice: '
options=("Autoypass on Recovery" "Check MDM Enrollment" "Reboot" "Exit")

select opt in "${options[@]}"; do
    case $opt in
    "Autoypass on Recovery")
        echo -e "\n\t${GREEN}Bypass on Recovery${NC}\n"

        # Mount Volumes
        echo -e "${BLUE}Mounting volumes...${NC}"
        # Mount System Volume
        systemVolumePath=$(defineVolumePath "$DEFAULT_SYSTEM_VOLUME" "System")
        mountVolume "$systemVolumePath"

        # Mount Data Volume
        dataVolumePath=$(defineVolumePath "$DEFAULT_DATA_VOLUME" "Data")
        mountVolume "$dataVolumePath"

        echo -e "${GREEN}Volume preparation completed${NC}\n"

        # Create User
        echo -e "${BLUE}Checking user existence${NC}"
        dscl_path="$dataVolumePath/private/var/db/dslocal/nodes/Default"
        localUserDirPath="/Local/Default/Users"
        
        # Define default values
        defaultFullName="Apple"
        defaultUsername="Apple" 
        defaultPassword="1234"
        
        echo -e "${CYAN}Press Enter to continue, Note: Leaving it blank will use default values${NC}"
        echo -e "${CYAN}Enter Full Name (Default: Apple)${NC}"
        read -rp "Full name: " fullName
        fullName="${fullName:=$defaultFullName}"

        echo -e "${CYAN}Username${NC} ${RED}WRITE WITHOUT SPACES${NC} ${GREEN}(default: Apple)${NC}"
        read -rp "Username: " username
        username="${username:=$defaultUsername}"

        echo -e "${CYAN}Enter the User Password (default: 1234)${NC}"
        read -rsp "Password: " userPassword
        userPassword="${userPassword:=$defaultPassword}"

        echo -e "\n${BLUE}Creating User${NC}"
        
        # Try to create user with better error handling
        if createUserSafely "$dscl_path" "$localUserDirPath" "$username" "$fullName" "$userPassword"; then
            echo -e "${GREEN}User creation completed${NC}\n"
        else
            echo -e "${RED}User creation failed${NC}\n"
            echo -e "${YELLOW}Note: The script will continue with MDM bypass even if user creation failed${NC}\n"
        fi

        # Block MDM hosts
        echo -e "${BLUE}Blocking MDM hosts...${NC}"
        hostsPath="$systemVolumePath/etc/hosts"
        blockedDomains=("deviceenrollment.apple.com" "mdmenrollment.apple.com" "iprofiles.apple.com")
        for domain in "${blockedDomains[@]}"; do
            echo "0.0.0.0 $domain" >>"$hostsPath"
        done
        echo -e "${GREEN}Successfully blocked host${NC}\n"

        # Remove config profiles
        echo -e "${BLUE}Remove config profiles${NC}"
        configProfilesSettingsPath="$systemVolumePath/var/db/ConfigurationProfiles/Settings"
        touch "$dataVolumePath/private/var/db/.AppleSetupDone"
        # Safe removal of config profiles
        if [ -f "$configProfilesSettingsPath/.cloudConfigHasActivationRecord" ]; then
            rm -f "$configProfilesSettingsPath/.cloudConfigHasActivationRecord"
        fi
        if [ -f "$configProfilesSettingsPath/.cloudConfigRecordFound" ]; then
            rm -f "$configProfilesSettingsPath/.cloudConfigRecordFound"
        fi
        rm -rf "$configProfilesSettingsPath/.cloudConfigProfileInstalled"
        rm -rf "$configProfilesSettingsPath/.cloudConfigRecordNotFound"
        echo -e "${GREEN}Config profiles removed${NC}\n"

        # Set up Apple Setup Done flag
        setupAppleSetupDone

        echo -e "${GREEN}------ Autobypass SUCCESSFULLY ------${NC}"
        echo -e "${CYAN}------ Exit Terminal. Reboot Macbook and ENJOY ! ------${NC}"
        break
        ;;

    "Check MDM Enrollment")
        if [ ! -f /usr/bin/profiles ]; then
            echo -e "\n\t${RED}Don't use this option in recovery${NC}\n"
            continue 2 # This will break out of the select loop
        fi

        if ! sudo profiles show -type enrollment >/dev/null 2>&1; then
            echo -e "\n\t${GREEN}Not Enrolled${NC}\n"
        else
            echo -e "\n\t${RED}Enrolled${NC}\n"
        fi
        ;;

    "Reboot")
        echo -e "\n\t${BLUE}Rebooting...${NC}\n"
        reboot
        ;;

    "Exit")
        echo -e "\n\t${BLUE}Exiting...${NC}\n"
        exit
        ;;

    *)
        echo "Invalid option $REPLY"
        ;;
    esac
done

echo "Script execution completed."
