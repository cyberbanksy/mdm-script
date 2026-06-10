https://github.com/cyberbanksy/mdm-script/tree/main
		echo -e "${GREEN}Volume preparation completed${NC}\n"

		# Create User
		echo -e "${BLUE}Checking user existence${NC}"
		dscl_path="$dataVolumePath/private/var/db/dslocal/nodes/Default"
		localUserDirPath="/Local/Default/Users"
		defaultUID="501"
		if ! dscl -f "$dscl_path" localhost -list "$localUserDirPath" UniqueID | grep -q "\<$defaultUID\>"; then
			echo -e "${CYAN}Create a new user${NC}"
			echo -e "${CYAN}Press Enter to continue, Note: Leaving it blank will default to the automatic user${NC}"
			echo -e "${CYAN}Enter Full Name (Default: Apple)${NC}"
			read -rp "Full name: " fullName
			fullName="${fullName:=Apple}"

			echo -e "${CYAN}Username${NC} ${RED}WRITE WITHOUT SPACES${NC} ${GREEN}(default: Apple)${NC}"
			read -rp "Username: " username
			username="${username:=Apple}"

			echo -e "${CYAN}Enter the User Password (default: 1234)${NC}"
			read -rsp "Password: " userPassword
			userPassword="${userPassword:=1234}"

			echo -e "\n${BLUE}Creating User${NC}"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UserShell "/bin/zsh"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" RealName "$fullName"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UniqueID "$defaultUID"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" PrimaryGroupID "20"
			mkdir "$dataVolumePath/Users/$username"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" NFSHomeDirectory "/Users/$username"
			dscl -f "$dscl_path" localhost -passwd "$localUserDirPath/$username" "$userPassword"
			dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"
			echo -e "${GREEN}User created${NC}\n"
		else
			echo -e "${BLUE}User already created${NC}\n"
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
		rm -rf "$configProfilesSettingsPath/.cloudConfigHasActivationRecord"
		rm -rf "$configProfilesSettingsPath/.cloudConfigRecordFound"
		touch "$configProfilesSettingsPath/.cloudConfigProfileInstalled"
		touch "$configProfilesSettingsPath/.cloudConfigRecordNotFound"
		echo -e "${GREEN}Config profiles removed${NC}\n"

		echo -e "${GREEN}------ Autobypass SUCCESSFULLY ------${NC}"
		echo -e "${CYAN}------ Exit Terminal. Reboot Macbook and ENJOY ! ------${NC}"
		break
		;;

	"Check MDM Enrollment")
		if [ ! -f /usr/bin/profiles ]; then
			echo -e "\n\t${RED}Don't use this option in recovery${NC}\n"
			continue
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
