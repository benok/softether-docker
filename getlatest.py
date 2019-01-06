#!/usr/bin/env python3

import json
import requests

USER = 'SoftEtherVPN'
REPO = 'SoftEtherVPN_Stable'

r = requests.get('https://api.github.com/repos/%s/%s/releases/latest' % (USER, REPO))
o = r.json()

print (o)
