#!/bin/bash

DEV="Elan Touchpad"

ON=$(xinput list-props "$DEV" | awk -F ':' '$1 ~ "Device Enabled" {print $2}')

xinput set-prop "$DEV" "Device Enabled" $((1-"$ON"))
