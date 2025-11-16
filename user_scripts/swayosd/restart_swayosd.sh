#!/bin/sh

# Kill any existing swayosd-server instance.
# The '2>/dev/null' suppresses any error message
# if the process isn't found.
killall swayosd-server 2>/dev/null

# Start the new swayosd-server instance.
#
# - 'nohup': Allows the process to keep running even if the
#            shell or script that started it exits.
# - '> /dev/null 2>&1': Redirects all standard output (>) and
#                       standard error (2>&1) to /dev/null,
#                       so it produces no output or logs.
# - '&': Puts the process in the background, so this script
#        exits immediately without waiting for it.
nohup swayosd-server >/dev/null 2>&1 &
