#!/bin/bash

SSH_DIR="/root/.ssh"
KEY_PATH="$SSH_DIR/id_rsa"
EMAIL="adhbhut.gupta@hypr4.io"

echo "=== Step 0: Checking and installing Git if missing ==="
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing..."
    apt update && apt install -y git
else
    echo "Git is already installed."
fi

echo ""
cd /root
echo "=== Step 1: Auto-generating SSH key (no prompts) ==="
mkdir -p $SSH_DIR
chmod 700 $SSH_DIR

ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$KEY_PATH" -N ""

echo ""
echo "=== Step 2: Copy the following public key to GitHub (Settings → SSH and GPG Keys) ==="
echo "------------------------------------------------------------------"
cat "$KEY_PATH.pub"
echo "------------------------------------------------------------------"
echo ""
read -p "🔐 After adding this key to GitHub, press ENTER to continue..."

echo ""
echo "=== Step 3: Applying permissions ==="
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

echo "=== Step 4: Creating SSH config ==="
cat <<EOF > $SSH_DIR/config
Host github.com
  HostName github.com
  User git
  IdentityFile $KEY_PATH
  IdentitiesOnly yes
EOF

chmod 600 "$SSH_DIR/config"

echo ""
echo "=== Step 5: Testing SSH connection with GitHub ==="
ssh -T git@github.com || true

echo ""
echo "🚀 Setup Complete!"
echo "If the previous line shows 'Hi <your_github_username>!', SSH authentication is working."
echo "Now you can clone repos using:"
echo "  git clone git@github.com:username/repo.git"
