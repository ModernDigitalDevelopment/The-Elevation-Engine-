# Elevation Flash Loan AI Bot (Python v1)
# Connects to Web3, reads best strategy, triggers flash loan

import os
import json
from web3 import Web3
from dotenv import load_dotenv

# Load config
load_dotenv()
w3 = Web3(Web3.HTTPProvider(os.getenv("WEB3_PROVIDER")))

private_key = os.getenv("PRIVATE_KEY")
wallet_address = Web3.to_checksum_address(os.getenv("WALLET_ADDRESS"))
contract_address = Web3.to_checksum_address(os.getenv("CONTRACT_ADDRESS"))
asset_address = Web3.to_checksum_address(os.getenv("ASSET_ADDRESS"))

# Load ABI
with open("ElevationFlashLoanBot_ABI.json", "r") as abi_file:
    abi = json.load(abi_file)

contract = w3.eth.contract(address=contract_address, abi=abi)

# Simulate AI strategy selection
with open("strategy_evaluation_report.json", "r") as strategy_file:
    strategy = json.load(strategy_file)[0]

print(f"🚀 Strategy: {strategy['category']} | Yield: {strategy['simulated_yield']}%")

# Set loan amount (1000 USDC = 1000 * 10^6)
amount = Web3.to_wei(1000, 'mwei')

# Build and sign the transaction
txn = contract.functions.triggerFlashLoan(asset_address, amount).build_transaction({
    'from': wallet_address,
    'nonce': w3.eth.get_transaction_count(wallet_address),
    'gas': 500000,
    'gasPrice': w3.to_wei('5', 'gwei')
})

signed_txn = w3.eth.account.sign_transaction(txn, private_key)
tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)

print(f"✅ Flash loan triggered! TX hash: {tx_hash.hex()}")
