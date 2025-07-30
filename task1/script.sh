#!/bin/bash


# Add a user
sudo useradd ali

# Delete user
sudo userdel ali

# Create file and change permission - method 1 (numeric)
touch myfile.txt
chmod 755 myfile.txt

# Change permission - method 2 (symbolic)
chmod u=rwx,g=rx,o=rx myfile.txt

# Create and delete folder
mkdir myfolder
rm -rf myfolder

# Preview data in file
echo "Hello from inside the file" > myfile.txt
cat myfile.txt
head myfile.txt
tail myfile.txt

# Make one alias only (for clear)
alias c='clear'
echo "alias c='clear'" >> ~/.bashrc

# Faster file search (instead of full root)
find . -name "myfile.txt"

# Print last commands
echo "📜 Last 5 history commands:"
history | tail -n 5

# Print working directory and date
pwd
date
cp myfile.txt copied.txt
mv copied.txt moved.txt
mv moved.txt renamed.txt
rm renamed.txt

# Delete directory (force)
mkdir myfolder2 && rm -r myfolder2

echo " Script completed."
