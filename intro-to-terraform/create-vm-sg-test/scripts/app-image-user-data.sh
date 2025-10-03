#!/bin/bash

# Purpose: Start the Node.js app with PM2 and connect it to MongoDB
# Tested on: AWS EC2, Ubuntu 22.04 LTS
# Intended to work on: fresh instances & VMs; idempotent
# Tested by: Charley
# Date tested: 23/09/25

echo "Entering project folder..."
cd "$WORKDIR/sparta-first-app/app"
echo "Entered project folder."
echo

echo "Setting environment variable..."
export DB_HOST="mongodb://${db_ip}:27017/posts"
echo "DB_HOST set to $DB_HOST"
echo

echo "Starting app with PM2..."
pm2 start app.js --name app
echo "PM2 start done."
echo