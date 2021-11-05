#!/usr/bin/env bash

set -e
# set -x

# This script will initiate the transition to protocol version 5 (Alonzo).

# You need to provide the current epoch as a positional argument (the Shelley
# update system requires this to be included in the update proposal).


# In order for this to be successful, you need to already be in protocol version
# 4 (which happens one or two epoch boundaries after invoking update-4.sh).
# Also, you need to restart the nodes after running this script in order for the
# update to be endorsed by the nodes.

if [ ! "$1" ]; then echo "update-5.sh: expects an <N> epoch argument"; exit; fi

EPOCH=$1
VERSION=5

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. "${SCRIPT_PATH}"/config-read.shlib; # load the config library functions

ROOT="$(config_get ROOT)";
INIT_SUPPLY="$(config_get INIT_SUPPLY)"

COINS_IN_INPUT=$((${INIT_SUPPLY} - 4000000))

FEE=1000000

pushd ${ROOT}

export CARDANO_NODE_SOCKET_PATH=node-pool1/node.sock

TXID2=$(cardano-cli transaction txid --tx-file tx3.tx)


# Create the update proposal to change the protocol version to 5

cardano-cli governance create-update-proposal \
            --out-file update-proposal-alonzo \
            --epoch ${EPOCH} \
            --genesis-verification-key-file shelley/genesis-keys/genesis1.vkey \
            --genesis-verification-key-file shelley/genesis-keys/genesis2.vkey \
            --protocol-major-version ${VERSION} \
            --protocol-minor-version 0

# Create a transaction body containing the update proposal.

afterFee=$((${COINS_IN_INPUT} - ${FEE}))
cardano-cli transaction build-raw \
            --mary-era \
            --fee ${FEE} \
            --tx-in $TXID2#0\
            --tx-in $TXID2#1\
            --tx-out $(cat addresses/user1.addr)+$((${afterFee} / 2)) \
            --tx-out $(cat addresses/user1.addr)+$((${afterFee} / 2)) \
            --update-proposal-file update-proposal-alonzo \
            --out-file tx4.txbody

# Sign the transaction body with the two genesis delegate keys,
# and the the uxto spending key.

cardano-cli transaction sign \
            --signing-key-file addresses/user1.skey \
            --signing-key-file shelley/delegate-keys/delegate1.skey \
            --signing-key-file shelley/delegate-keys/delegate2.skey \
            --testnet-magic 42 \
            --tx-body-file  tx4.txbody \
            --out-file      tx4.tx


cardano-cli transaction submit --tx-file tx4.tx --testnet-magic 42

OS=$(uname -s) SED=
case $OS in
  Darwin )       SED="gsed";;
  * )            SED="sed";;
esac

$(${SED} -i configuration.yaml \
    -e 's/LastKnownBlockVersion-Major: 4/LastKnownBlockVersion-Major: 5/' \
)
popd

echo "Restart the nodes now to endorse the update."


