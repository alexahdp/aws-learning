#!/bin/sh

. ~/.nvm/nvm.sh
cd /home/www/appexample
pm2 start ecosystem.config.js