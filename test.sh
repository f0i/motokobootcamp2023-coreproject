#!/usr/bin/env bash

dao="dfx canister call dao_backend"

set -eu -o pipefail
function assert() {
    tee /dev/tty |
        (grep -q -- "$1" || (
            echo -e "\n -------\n"
            echo -e "ASSERT FAILED: did not contain '$1'\n"
            local line_no=$(caller 0 | awk '{print $1}')
            echo -n -e "last command was\n $0:$line_no: "
            sed -n "${line_no}p" "$0"
            echo
            exit 1
        ))
}

dfx identity use default

# $dao submitProposal '("Hello script!")'
$dao getProposals '(-1, 1)' | assert "Hello script!"

echo "All test passed"
