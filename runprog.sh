#! /bin/sh
#chmod u+x runprog.sh
#!/bin/bash

# Make sure python is 2.7 or later
PYTHON_OK=`python -c 'import sys
print (sys.version_info >= (2, 7) and "1" or "0")'`

echo "python ok: $PYTHON_OK"

if [ "$PYTHON_OK" = '0' ]; then
    echo "Python version too old. Need 2.7 above"
else
    echo "Python is ok launching tool"
    python indexLinux.py
fi

