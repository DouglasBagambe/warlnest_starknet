# WarlNest Starknet Smart Contracts

## Overview

This directory contains the Cairo smart contracts that power WarlNest's blockchain layer on Starknet. These contracts provide immutable property verification, secure escrow, and transparent reputation management for the real estate platform.

## Contracts

### 1. PropertyRegistry.cairo
**Purpose**: Tokenize and verify property listings as NFTs

**Key Features**:
- Mint property NFTs with unique metadata
- Verify properties through authorized verifiers
- Track complete ownership history on-chain
- Update property prices and metadata
- Prevent duplicate property listings

**Use Cases**:
- Property owners mint their listings as NFTs
- Government/authorized agents verify legitimate properties
- Buyers can see complete ownership history
- Price changes are tracked transparently

### 2. Escrow.cairo
**Purpose**: Secure payment handling for bookings, deposits, and full payments

**Key Features**:
- Create escrow for booking fees, deposits, or full payments
- Automated fund release based on conditions
- Dispute resolution mechanism
- Refund capabilities
- Multi-party arbitration

**Use Cases**:
- Buyers deposit booking fees securely
- Rental deposits held in escrow
- Dispute resolution for failed transactions
- Automated release when conditions are met

### 3. Reputation.cairo
**Purpose**: Build trust through transparent agent and landlord ratings

**Key Features**:
- Agent registration and verification
- Immutable review system (1-5 star ratings)
- Fraud reporting mechanism
- Calculated reputation scores
- Prevent review manipulation

**Use Cases**:
- Agents build verifiable reputation
- Tenants leave honest reviews
- Fraud reports create accountability
- Buyers trust verified agents

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  WarlNest Backend (Node.js)             │
│  - Indexes blockchain events                            │
│  - Syncs on-chain data with MongoDB                     │
│  - Provides API for Flutter app                         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Starknet Network (Sepolia/Mainnet)         │
│                                                          │
│  ┌──────────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ PropertyRegistry │  │    Escrow    │  │ Reputation│ │
│  │                  │  │              │  │           │ │
│  │ - Mint NFTs      │  │ - Hold funds │  │ - Reviews │ │
│  │ - Verify props   │  │ - Disputes   │  │ - Scores  │ │
│  │ - Track history  │  │ - Release    │  │ - Fraud   │ │
│  └──────────────────┘  └──────────────┘  └───────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Building & Deployment

### Prerequisites
```bash
# Install Scarb (Cairo package manager)
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh

# Install Starknet Foundry
curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
```

### Build Contracts
```bash
cd starknet_contracts
scarb build
```

### Test Contracts
```bash
snforge test
```

### Deploy to Testnet (Sepolia)
```bash
# Deploy PropertyRegistry
starkli deploy target/dev/warlnest_contracts_PropertyRegistry.contract_class.json \
  --constructor-calldata <ADMIN_ADDRESS>

# Deploy Escrow
starkli deploy target/dev/warlnest_contracts_Escrow.contract_class.json \
  --constructor-calldata <ADMIN_ADDRESS>

# Deploy Reputation
starkli deploy target/dev/warlnest_contracts_Reputation.contract_class.json \
  --constructor-calldata <ADMIN_ADDRESS>
```

## Integration with WarlNest

### Backend Integration
The Node.js backend listens to contract events and syncs data:

```javascript
// Example: Listen to PropertyMinted events
const provider = new Provider({ sequencer: { network: 'sepolia' } });
const contract = new Contract(abi, contractAddress, provider);

contract.on('PropertyMinted', (event) => {
  // Sync to MongoDB
  Property.findByIdAndUpdate(event.property_id, {
    blockchainTokenId: event.token_id,
    verified: false,
    onChain: true
  });
});
```

### Flutter Integration
The mobile app interacts via Starknet.js:

```dart
// Example: Mint property NFT
final account = StarknetAccount(...);
final contract = StarknetContract(address: registryAddress);

final result = await contract.invoke(
  'mint_property',
  [propertyId, owner, metadataUri, price, propertyType, locationHash]
);
```

## Security Considerations

1. **Access Control**: Only authorized verifiers can verify properties
2. **Dispute Resolution**: Multi-signature arbitration for escrow disputes
3. **Fraud Prevention**: Immutable fraud reports create accountability
4. **Review Integrity**: One review per property per user
5. **Ownership Verification**: Complete on-chain history prevents fraud

## Events Emitted

### PropertyRegistry
- `PropertyMinted`: New property tokenized
- `PropertyVerified`: Property verified by authority
- `PropertyTransferred`: Ownership changed
- `PriceUpdated`: Price modified
- `MetadataUpdated`: Listing details updated

### Escrow
- `EscrowCreated`: New escrow initiated
- `FundsDeposited`: Buyer deposited funds
- `FundsReleased`: Seller received payment
- `FundsRefunded`: Buyer refunded
- `DisputeRaised`: Dispute initiated
- `DisputeResolved`: Dispute settled

### Reputation
- `AgentRegistered`: New agent joined
- `AgentVerified`: Agent verified by authority
- `ReviewAdded`: New review submitted
- `FraudReported`: Fraud report filed

## Gas Optimization

All contracts are optimized for Starknet's low-fee environment:
- Efficient storage patterns
- Minimal computation in hot paths
- Event-driven architecture for off-chain indexing

## Roadmap

- [x] Core contracts (PropertyRegistry, Escrow, Reputation)
- [ ] ERC-721 compliance for property NFTs
- [ ] Token-based payments (USDC/STRK)
- [ ] Fractional ownership support
- [ ] DAO governance for dispute resolution
- [ ] Cross-chain bridge to Ethereum L1

## License

MIT License - See LICENSE file for details

## Support

For questions or issues:
- GitHub Issues: [warlnest/issues](https://github.com/warlnest/issues)
- Email: douglasbagambe4@gmail.com
