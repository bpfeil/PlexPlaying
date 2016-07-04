#!/bin/bash

API="$1"
MSG="$2"

curl -u $1: https://api.pushbullet.com/v2/pushes -d type=note -d title="Alert" -d body="$MSG"
