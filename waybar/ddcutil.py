#!/usr/bin/env python

import subprocess
import json

data = {}
cmd = ["ddcutil", "getvcp", "10", "--bus", "9"]
value = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf8')
# output looks like this in my case: VCP code 0x10 (Brightness                    ): current value =    20, max value =   100
percentage = value.split(",")[0][-3:].strip(" ")
data['percentage'] = int(percentage)
print(json.dumps(data))
