#!/usr/bin/env bash

set -e
# set -x

# This script will initiate the transition to protocol version 2 (Shelley).

# In order for this to be successful, you need to already be in protocol version
# 1 (which happens one or two epoch boundaries after invoking update-1.sh).
# Also, you need to restart the nodes after running this script in order for the
# update to be endorsed by the nodes.

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. "${SCRIPT_PATH}"/config-read.shlib; # load the config library functions

ROOT="$(config_get ROOT)";

pushd ${ROOT}

export CARDANO_NODE_SOCKET_PATH=node-bft1/node.sock

cardano-cli byron submit-update-proposal \
            --testnet-magic 42 \
            --filepath update-proposal-1

sleep 2
cardano-cli byron submit-proposal-vote  \
            --testnet-magic 42 \
            --filepath update-vote-1.000
cardano-cli byron submit-proposal-vote  \
            --testnet-magic 42 \
            --filepath update-vote-1.001


OS=$(uname -s) SED=
case $OS in
  Darwin )       SED="gsed";;
  * )            SED="sed";;
esac


$(${SED} -i configuration.yaml \
    -e 's/LastKnownBlockVersion-Major: 1/LastKnownBlockVersion-Major: 2/' \
)
popd


