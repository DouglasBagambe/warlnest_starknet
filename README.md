# WarlNest - Blockchain-Powered Real Estate Platform

**Verified. Trusted. On-Chain.**

WarlNest is revolutionizing African real estate by combining traditional property listings with Starknet blockchain technology to eliminate fraud, ensure transparency, and build trust.

---

## What is WarlNest?

WarlNest is a comprehensive PropTech platform that solves Uganda's $50M+ annual land fraud problem by:

- **Verifying Properties** - Every listing backed by blockchain verification
- **Securing Payments** - Escrow smart contracts protect buyers and sellers
- **Building Trust** - Immutable agent reputation system
- **Tracking History** - Complete on-chain ownership records

---

## The Problem We're Solving

### Uganda's Real Estate Crisis
- **2.4M housing shortage** across the country
- **60%+ informal market** with zero verification
- **Rampant fraud** - fake agents, duplicate titles, price manipulation
- **No trust layer** - buyers have no way to verify claims

### Personal Story
Our founder was scammed twice by unverified brokers. Lost deposits. Wasted time. WarlNest was born from this pain.

---

## Our Solution

### Three-Layer Architecture

#### 1. Traditional Layer (Live)
- Flutter mobile app (Android/iOS/Web)
- Node.js backend with MongoDB
- 500+ properties, 2,000+ users
- Advanced search, filters, booking

#### 2. Blockchain Layer (Starknet)
- **PropertyRegistry** - Mint properties as NFTs, verify ownership
- **Escrow** - Secure payments, dispute resolution
- **Reputation** - Immutable agent ratings, fraud reporting

#### 3. Integration Layer
- Seamless wallet integration
- Event indexing and sync
- Blockchain invisible to end users

---

## Technical Stack

### Frontend
- **Flutter** - Cross-platform mobile (Android, iOS, Web)
- **Provider** - State management
- **Starknet.js** - Wallet integration

### Backend
- **Node.js + Express** - REST API
- **MongoDB** - Property data, metadata
- **Starknet.js** - Contract interaction, event indexing

### Blockchain
- **Cairo** - Smart contract language
- **Starknet** - Layer 2 network
- **Scarb** - Package manager
- **Starknet Foundry** - Testing framework

---

## Project Structure

```
warlnest/
├── frontend/                 # Flutter mobile app
│   ├── lib/
│   │   ├── models/               # Data models
│   │   ├── providers/            # State management (incl. Starknet)
│   │   ├── screens/              # UI screens
│   │   ├── services/             # API & Starknet services
│   │   └── widgets/              # Reusable components
│   └── pubspec.yaml
│
├── backend/         # Node.js API
│   ├── models/                   # MongoDB schemas
│   ├── routes/                   # API endpoints (incl. Starknet)
│   ├── services/                 # Business logic, Starknet integration
│   ├── server.js                 # Entry point
│   └── package.json
│
├── contracts/            # Cairo smart contracts
│   ├── src/
│   │   ├── property_registry.cairo  # Property NFT contract
│   │   ├── escrow.cairo            # Payment escrow contract
│   │   ├── reputation.cairo        # Agent reputation contract
│   │   └── interfaces.cairo        # Contract interfaces
│   ├── Scarb.toml                # Package config
│   └── README.md                 # Contract documentation
│
└── README.md                     # This file
```

---

## Key Features

### For Buyers/Renters
- Browse verified properties
- Secure escrow payments
- View agent reputation scores
- Check property ownership history
- Report fraud with on-chain evidence

### For Agents/Landlords
- Mint properties as NFTs
- Get verified badge
- Build immutable reputation
- Receive secure payments
- Track listing performance

### For the Ecosystem
- Transparent property data
- Fraud prevention
- Ownership verification
- Price history tracking
- Data for lending, insurance, planning

---

## Smart Contracts

### PropertyRegistry.cairo
**Purpose**: Tokenize and verify properties

**Key Functions**:
- `mint_property()` - Create property NFT
- `verify_property()` - Admin verification
- `transfer_property()` - Ownership change
- `get_property_history()` - Complete audit trail

**Events**:
- PropertyMinted
- PropertyVerified
- PropertyTransferred
- PriceUpdated

### Escrow.cairo
**Purpose**: Secure payment handling

**Key Functions**:
- `create_escrow()` - Initialize payment
- `deposit_funds()` - Buyer deposits
- `release_funds()` - Seller receives
- `dispute_escrow()` - Raise dispute
- `resolve_dispute()` - Arbitration

**States**:
- 0: pending
- 1: funded
- 2: released
- 3: refunded
- 4: disputed

### Reputation.cairo
**Purpose**: Build trust through ratings

**Key Functions**:
- `register_agent()` - Agent onboarding
- `add_review()` - Immutable ratings (1-5 stars)
- `report_fraud()` - Accountability
- `get_agent_score()` - Calculated reputation

**Features**:
- One review per property per user
- On-chain score calculation
- Immutable reviews
- Fraud report tracking

---

## Getting Started

### Quick Start (Development)

1. **Clone Repository**
```bash
git clone https://github.com/DouglasBagambe/warlnest_starknet
cd warlnest_starknet
```

2. **Deploy Smart Contracts**
```bash
cd contracts
scarb build
```

3. **Start Backend**
```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

4. **Run Mobile App**
```bash
cd frontend
flutter pub get
flutter run
```
---

## Why Starknet?

1. **Low Fees** - $13 per property lifecycle vs. $200+ on Ethereum
2. **Scalability** - Can handle millions of properties
3. **Cairo** - Provable computation for verification
4. **African Focus** - Starknet Africa community
5. **Data Integrity** - Perfect for property records

---

## Team

**Ainamaani Douglas Bagambe** - Founder & CEO
- Full-stack developer (Node.js, Flutter, Cairo)
- Passionate about solving African problems with blockchain

**Partners**
- Ahabwe Arnold(Warlem) - Partner

---

## Security

- Smart contracts written in Cairo (provably secure)
- Pending professional audit (Nethermind/Trail of Bits)
- Private keys never stored in code
- HTTPS/TLS for all endpoints
- Input validation on all routes
- Rate limiting enabled

---

## License

MIT License - See LICENSE file for details

---

## Contact

**Email**: douglasbagambe4@gmail.com
**Location**: Kampala, Uganda

---

## Our Mission

**To eliminate land fraud in Africa by putting property verification on the blockchain.**

Every property verified. Every transaction secured. Every agent accountable.

**WarlNest - Building trust, one property at a time.**

---

**Ready to revolutionize African real estate? Let's build together!**
