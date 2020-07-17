#!/usr/bin/env bash
set -e

# [[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp --use solc:0.5.12 build

# MkrAuthority
# export DAPP_TEST_ADDRESS=0x6a3AE20C315E845B2E398e68EfFe39139eC6060C
export DAPP_TEST_ADDRESS=0xdB33dFD3D61308C33C63209845DaD3e6bfb2c674
export DAPP_TEST_TIMESTAMP=$(seth block latest timestamp)
export DAPP_TEST_NUMBER=$(seth block latest number)

LANG=C.UTF-8 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --verbose 1
