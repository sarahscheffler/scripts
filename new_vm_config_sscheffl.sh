#!/bin/bash

# Creates the sscheffl user, adds it to sudoers, sets zeke's key as its public key, downloads and sets up dotifles, and downloads convenience packages.

set -e  # Exit on any error

USERNAME="sscheffl"
USER_HOME="/home/$USERNAME"
PUBLIC_KEY="ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNIUgaOjZ2OrO7J3M4EEfDBTxXKsXy3TzD1nIFb6JHb2C9jp8jFIdJTvWNdBX4RbNkysq03UK/lL0rMakB3monU= sscheffl@zeke"

# 1. Create the user if not exists
if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists."
else
    echo "Creating user $USERNAME..."
    adduser --disabled-password --gecos "" "$USERNAME"
fi

# 2. Ensure sudo group exists and user is added
if ! getent group sudo > /dev/null; then
    echo "Creating sudo group..."
    groupadd sudo
    echo "%sudo ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

echo "Adding $USERNAME to sudo group..."
usermod -aG sudo "$USERNAME"

# 3. Add public SSH key
echo "Setting up SSH authorized_keys..."
mkdir -p "$USER_HOME/.ssh"
echo "$PUBLIC_KEY" > "$USER_HOME/.ssh/authorized_keys"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"

# 4. Update and install base packages
echo "Installing base packages..."
apt update
apt install -y git tmux neovim curl wget

# 5. Clone dotfiles repository
DOTFILES_DIR="$USER_HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repo..."
    sudo -u "$USERNAME" git clone https://github.com/sarahscheffler/dotfiles "$DOTFILES_DIR"
else
    echo "Dotfiles repo already exists, skipping clone."
fi

# 6. Run dotfiles setup script
if [ -f "$DOTFILES_DIR/makesymlinks.sh" ]; then
    echo "Running makesymlinks.sh..."
    sudo -u "$USERNAME" bash "$DOTFILES_DIR/makesymlinks.sh"
else
    echo "Warning: makesymlinks.sh not found, skipping."
fi

# 7. Final message
echo "Setup complete for user $USERNAME."

