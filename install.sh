#!/bin/sh

# Copy the gpterm.sh file to /usr/local/bin
cp gpterm.sh /usr/local/bin/gpterm
sudo chmod +x /usr/local/bin/gpterm

# Append the alias command to the appropriate shell config file
if [ "$SHELL" = "/bin/bash" ]; then
  echo "alias gpterm='bash /usr/local/bin/gpterm'" >> ~/.bashrc
elif [ "$SHELL" = "/bin/zsh" ]; then
  echo "alias gpterm='bash /usr/local/bin/gpterm'" >> ~/.zshrc
else
  echo "Unknown shell: $SHELL. Alias not added."
fi