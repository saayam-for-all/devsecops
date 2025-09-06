#!/bin/bash
cd ~/devsecops
npm install
pkill node || true
nohup node app.js > output.log 2>&1 &
