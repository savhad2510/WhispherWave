#!/usr/bin/env bash

CANISTER_IDS_JSON="canister_ids.json"
CANISTER=$1
NETWORK=${2:-local}
test "$NETWORK" = "local" && CANISTER_IDS_JSON=".dfx/local/${CANISTER_IDS_JSON}"

test ! -f "./dist/${NETWORK}" && echo ./dist/${NETWORK} does not exist && exit 1

CANISTER_ID=$(cat "$CANISTER_IDS_JSON" | jq -r ".${CANISTER}.${NETWORK}")

test "${CANISTER_ID}" != "null" && echo "$CANISTER already created on network $NETWORK" && exit 0

echo Creating canister ${CANISTER} on network ${NETWORK}

OUTPUT_FILE=$(mktemp --tmpdir out-XXXXXXXX)
ICREPL_FILE=$(mktemp ic-repl.XXXXXXXX)
cat >"$ICREPL_FILE" <<END
  identity private "dist/identity.pem";
  load "./dist/${NETWORK}";
  load "./scripts/functions";
  let ${CANISTER} = create_canister();
  export "$OUTPUT_FILE";
END
ic-repl "$ICREPL_FILE" >/dev/null
test "$?" != "0" && rm -f "$OUTPUT_FILE" "$ICREPL_FILE" && exit 1
CANISTER_ID=$(grep "^let ${CANISTER}" "$OUTPUT_FILE" | sed -e 's/^.*principal "\(.*\)";/\1/')
rm -f "$OUTPUT_FILE" "$ICREPL_FILE"

JSON_FILE=$(mktemp --tmpdir out-XXXXXXXX)
cat "$CANISTER_IDS_JSON" | jq ".${CANISTER} = { \"local\": \"${CANISTER_ID}\" }" >"$JSON_FILE"
mv "$JSON_FILE" "$CANISTER_IDS_JSON"
