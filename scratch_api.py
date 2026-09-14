import urllib.request
import json

try:
    req = urllib.request.Request("http://localhost:8000/api/admin/pos/history?shop_id=shop123") # We might get 401 Unauthorized without token, but maybe it's not protected? Or maybe we can get a shop id.
    with urllib.request.urlopen(req) as response:
        print(response.read().decode())
except Exception as e:
    print(e)
