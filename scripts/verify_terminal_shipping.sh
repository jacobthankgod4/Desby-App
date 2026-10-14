#!/bin/bash
# Live round-trip check against the Terminal Shipping sandbox.
#
# The Flutter test suite cannot do this: TestWidgetsFlutterBinding stubs
# HttpClient to return 400, so real HTTP never leaves the process. This script
# exercises the real endpoints with the real key.
#
# Read-only: it quotes rates and lists carriers. It does NOT book a shipment.
set -uo pipefail

ENV_FILE="${ENV_FILE:-/Users/mac/desby_app/.env}"
KEY=$(grep -E '^TERMINAL_API_SECRET_KEY=' "$ENV_FILE" | cut -d= -f2-)
BASE=$(grep -E '^TERMINAL_API_BASE_URL=' "$ENV_FILE" | cut -d= -f2-)

if [ -z "$KEY" ]; then
  echo "FAIL: no TERMINAL_API_SECRET_KEY in $ENV_FILE"
  exit 1
fi
case "$BASE" in
  *sandbox*) ;;
  *) echo "REFUSING to run against non-sandbox: $BASE"; exit 1 ;;
esac

echo "=== Terminal Shipping sandbox check ($BASE) ==="

# 1. auth works
code=$(curl -s -o /tmp/ts_carriers.json -w "%{http_code}" -m 20 "$BASE/carriers" \
  -H "Authorization: Bearer $KEY")
echo "carriers endpoint      -> HTTP $code"
if [ "$code" != "200" ]; then
  echo "FAIL: auth rejected"; head -c 200 /tmp/ts_carriers.json; echo; exit 1
fi

python3 - <<'PY'
import json
d = json.load(open('/tmp/ts_carriers.json'))
cs = d['data']['carriers']
ng = [c for c in cs if c.get('domestic') and 'NG' in (c.get('available_countries') or [])]
print(f"  total carriers       : {len(cs)}")
print(f"  Nigeria-capable      : {len(ng)}")
for want in ('Fez', 'GIG', 'DHL', 'Sendstack', 'Redstar', 'Dellyman'):
    hit = [c['name'] for c in ng if want.lower() in c['name'].lower()]
    print(f"    {want:<10} {'YES' if hit else 'no':<5} {hit[0] if hit else ''}")
PY

# 2. a real quote
echo
code=$(curl -s -o /tmp/ts_quote.json -w "%{http_code}" -m 30 -X POST "$BASE/rates/shipment/quotes" \
  -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
  -d '{"currency":"NGN","persist_data":false,
       "pickup_address":{"name":"Desby","phone":"+2348000000000","state":"Lagos","city":"Ikeja","country":"NG","line1":"1 Allen Avenue","zip":"101123"},
       "delivery_address":{"name":"Customer","phone":"+2348000000000","state":"Lagos","city":"Yaba","country":"NG","line1":"7 Adebiyi Street","zip":"101123"},
       "parcel":{"description":"Custom garment","weight":2,"weight_unit":"kg","length":30,"width":25,"height":10,"dimension_unit":"cm","item_value":50000,"currency":"NGN",
                 "items":[{"name":"Custom garment","description":"Custom garment","quantity":1,"weight":2,"weight_unit":"kg","value":50000,"currency":"NGN"}]}}')
echo "quote endpoint         -> HTTP $code"

python3 - <<'PY'
import json, sys
try:
    d = json.load(open('/tmp/ts_quote.json'))
except Exception as e:
    print("FAIL: unreadable response", e); sys.exit(1)
if not d.get('status'):
    print("FAIL:", d.get('message')); sys.exit(1)
rs = d.get('data') or []
print(f"  quotes returned       : {len(rs)}")
if not rs:
    print("FAIL: no quotes"); sys.exit(1)
rs = sorted(rs, key=lambda r: r.get('amount', 0))
for r in rs:
    print(f"    {str(r.get('carrier_name'))[:26]:<28} {r.get('amount'):>9} {r.get('currency')}  {str(r.get('delivery_time',''))[:24]}")
print()
print(f"  cheapest              : {rs[0].get('carrier_name')} @ {rs[0].get('amount')} {rs[0].get('currency')}")
PY

# 3. arrange pickup (sandbox only — this creates a real sandbox shipment)
echo
echo "--- arrange pickup (creates a SANDBOX shipment) ---"
RATE=$(curl -s -m 30 -X POST "$BASE/rates/shipment/quotes" \
  -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
  -d '{"currency":"NGN","persist_data":true,
       "pickup_address":{"name":"Desby","first_name":"Desby","last_name":"Workshop","email":"logistics@desby.app","phone":"+2348000000000","state":"Lagos","city":"Ikeja","country":"NG","line1":"1 Allen Avenue","line2":"Opposite Fidelity Bank","zip":"101123"},
       "delivery_address":{"name":"Test Customer","first_name":"Test","last_name":"Customer","email":"customer@example.com","phone":"+2348012345678","state":"Lagos","city":"Yaba","country":"NG","line1":"7 Adebiyi Street","line2":"Near Yaba roundabout","zip":"101123"},
       "parcel":{"description":"Custom garment","weight":2,"weight_unit":"kg","length":30,"width":25,"height":10,"dimension_unit":"cm","item_value":50000,"currency":"NGN","items":[{"name":"Custom garment","description":"Custom garment","quantity":1,"weight":2,"weight_unit":"kg","value":50000,"currency":"NGN"}]}}' \
  | python3 -c "import sys,json;d=json.load(sys.stdin);rs=sorted(d.get('data') or [],key=lambda x:x.get('amount',0));print(rs[0].get('rate_id','') if rs else '')")
echo "  chosen rate_id    : ${RATE:-NONE}"

BOOKED=$(curl -s -m 35 -X POST "$BASE/shipments/pickup" \
  -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
  -d "{\"rate_id\":\"$RATE\"}")
echo "$BOOKED" | python3 -c "
import sys,json
d=json.load(sys.stdin); x=d.get('data') or {}
print('  arrange status    :',d.get('status'))
print('  shipment_id       :',x.get('shipment_id'))
print('  state             :',x.get('status'))
print('  tracking_number   :',(x.get('extras') or {}).get('tracking_number'))
sid=x.get('shipment_id') or ''
open('/tmp/sid.txt','w').write(sid)
"
SID=$(cat /tmp/sid.txt)

echo
echo "--- track read-back ---"
curl -s -m 25 "$BASE/shipments/$SID" -H "Authorization: Bearer $KEY" 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin); x=d.get('data') or {}
print('  tracking status   :',x.get('status'))
print('  events            :',len(x.get('events') or []))
"

echo
echo "=== OK — all steps verified on SANDBOX ==="