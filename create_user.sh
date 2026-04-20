#!/bin/bash

SUDO_GROUP="sietch"
SUDOER=false
DEFAULT_SHELL="/bin/bash"

# Usage is `./create_user.sh username` for a non-sudoer, 
# and `./create_user.sh username --sudoer` for a sudoer
for arg in "$@"; do
	case $arg in
	--sudoer) SUDOER=true ;;
	*) USERNAME=$arg ;;
	esac
done

if [ -z "$USERNAME" ]; then
	echo "Usage: $0 <username> [--sudoer]"
	exit 1
fi

# Add user
echo "Adding user '$USERNAME'..."
sudo useradd -m -s "$DEFAULT_SHELL" "$USERNAME"
sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME" # make them own their home dir

# If user should be sudoer, add them to the sudo group and set a temporary password
if [ "$SUDOER" = "true" ]; then
	echo "Since --sudoer is set, giving '$USERNAME' sudo permissions..."
	sudo usermod -aG "$SUDO_GROUP" "$USERNAME"

	echo "Enter a temporary password for '$USERNAME':"
	read -rs TEMP_PASS
	echo "$USERNAME:$TEMP_PASS" | sudo chpasswd
	sudo passwd -e "$USERNAME"
	echo "Temporary password set and marked as expired; '$USERNAME' will be prompted to change it on first login."

	printf "The administrator has granted you sudo privileges on this system.\nYour temporary password is: %s\nYou will be required to change it on first login." \
		"$TEMP_PASS" | sudo tee "/home/$USERNAME/README_SUDO.txt" > /dev/null
fi

# Create their .ssh folder with authorized_keys and config, and give them ownership
echo "Creating .ssh, authorized_keys, and config for '$USERNAME'..."
sudo mkdir -p "/home/$USERNAME/.ssh"
sudo touch "/home/$USERNAME/.ssh/authorized_keys"
sudo touch "/home/$USERNAME/.ssh/config"
#sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh" # this should be handled recursively but leaving it here until confirmed
sudo chmod 700 "/home/$USERNAME/.ssh"
sudo chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
sudo chmod 600 "/home/$USERNAME/.ssh/config"

# Optionally put the user's ssh key there
SSH_KEY_ADDED=false
echo "Paste the SSH public key for '$USERNAME' (or press Enter to skip):"
read -r SSH_PUBLIC_KEY
if [ -n "$SSH_PUBLIC_KEY" ]; then
        echo "$SSH_PUBLIC_KEY" | sudo tee -a "/home/$USERNAME/.ssh/authorized_keys" > /dev/null
        echo "SSH public key added."
        SSH_KEY_ADDED=true
else
        echo "No SSH key provided, skipping."
fi

# Done
echo "User '$USERNAME' created. Sudoer: $SUDOER. SSH key added: $SSH_KEY_ADDED"
