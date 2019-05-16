#!/bin/sh
## Ask to confirm an action
echo "$*"
echo "CONTINUE? [Y/N]: "; read ANSWER; \
if [ ! "$ANSWER" = "Y" ]; then \
    echo "Exiting." ; exit 1 ; \
fi
exit 0
