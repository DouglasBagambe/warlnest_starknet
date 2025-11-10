const { Provider, Contract, Account, ec, json, stark, uint256, shortString } = require('starknet');
const fs = require('fs');
const path = require('path');

class StarknetService {
  constructor() {
    // Initialize provider (Sepolia testnet by default)
    this.provider = new Provider({
      sequencer: {
        network: process.env.STARKNET_NETWORK || 'sepolia'
      }
    });

    // Contract addresses (to be set after deployment)
    this.propertyRegistryAddress = process.env.PROPERTY_REGISTRY_ADDRESS;
    this.escrowAddress = process.env.ESCROW_ADDRESS;
    this.reputationAddress = process.env.REPUTATION_ADDRESS;

    // Admin account (for verification and management)
    this.adminAccount = null;
    if (process.env.STARKNET_ADMIN_PRIVATE_KEY && process.env.STARKNET_ADMIN_ADDRESS) {
      this.adminAccount = new Account(
        this.provider,
        process.env.STARKNET_ADMIN_ADDRESS,
        process.env.STARKNET_ADMIN_PRIVATE_KEY
      );
    }

    // Contract instances
    this.propertyRegistry = null;
    this.escrow = null;
    this.reputation = null;

    this.initializeContracts();
  }

  async initializeContracts() {
    try {
      // Load compiled contract ABIs
      const propertyRegistryAbi = this.loadAbi('PropertyRegistry');
      const escrowAbi = this.loadAbi('Escrow');
      const reputationAbi = this.loadAbi('Reputation');

      if (this.propertyRegistryAddress && propertyRegistryAbi) {
        this.propertyRegistry = new Contract(
          propertyRegistryAbi,
          this.propertyRegistryAddress,
          this.provider
        );
        if (this.adminAccount) {
          this.propertyRegistry.connect(this.adminAccount);
        }
      }

      if (this.escrowAddress && escrowAbi) {
        this.escrow = new Contract(
          escrowAbi,
          this.escrowAddress,
          this.provider
        );
        if (this.adminAccount) {
          this.escrow.connect(this.adminAccount);
        }
      }

      if (this.reputationAddress && reputationAbi) {
        this.reputation = new Contract(
          reputationAbi,
          this.reputationAddress,
          this.provider
        );
        if (this.adminAccount) {
          this.reputation.connect(this.adminAccount);
        }
      }

      console.log('Starknet contracts initialized successfully');
    } catch (error) {
      console.error('Error initializing Starknet contracts:', error);
    }
  }

  loadAbi(contractName) {
    try {
      const abiPath = path.join(__dirname, '../../starknet_contracts/target/dev', `warlnest_contracts_${contractName}.contract_class.json`);
      if (fs.existsSync(abiPath)) {
        const contractClass = JSON.parse(fs.readFileSync(abiPath, 'utf8'));
        return contractClass.abi;
      }
      return null;
    } catch (error) {
      console.warn(`Could not load ABI for ${contractName}:`, error.message);
      return null;
    }
  }

  // ============ Property Registry Functions ============

  /**
   * Mint a property NFT on Starknet
   * @param {string} propertyId - MongoDB property ID
   * @param {string} ownerAddress - Starknet wallet address of owner
   * @param {string} metadataUri - IPFS or HTTP URI to property metadata
   * @param {number} price - Property price in wei
   * @param {number} propertyType - 0: apartment, 1: house, 2: villa, etc.
   * @param {string} locationHash - Hash of location data
   */
  async mintProperty(propertyId, ownerAddress, metadataUri, price, propertyType, locationHash) {
    if (!this.propertyRegistry) {
      throw new Error('PropertyRegistry contract not initialized');
    }

    try {
      // Convert property ID to felt252
      const propertyIdFelt = shortString.encodeShortString(propertyId.substring(0, 31));
      
      // Convert price to uint256
      const priceUint256 = uint256.bnToUint256(price);

      const result = await this.propertyRegistry.mint_property(
        propertyIdFelt,
        ownerAddress,
        metadataUri,
        priceUint256,
        propertyType,
        locationHash
      );

      await this.provider.waitForTransaction(result.transaction_hash);

      return {
        success: true,
        transactionHash: result.transaction_hash,
        tokenId: result.token_id
      };
    } catch (error) {
      console.error('Error minting property:', error);
      throw error;
    }
  }

  /**
   * Verify a property (admin only)
   */
  async verifyProperty(tokenId, verifierAddress) {
    if (!this.propertyRegistry || !this.adminAccount) {
      throw new Error('PropertyRegistry or admin account not initialized');
    }

    try {
      const result = await this.propertyRegistry.verify_property(
        uint256.bnToUint256(tokenId),
        verifierAddress
      );

      await this.provider.waitForTransaction(result.transaction_hash);

      return {
        success: true,
        transactionHash: result.transaction_hash
      };
    } catch (error) {
      console.error('Error verifying property:', error);
      throw error;
    }
  }

  /**
   * Get property details from blockchain
   */
  async getPropertyDetails(tokenId) {
    if (!this.propertyRegistry) {
      throw new Error('PropertyRegistry contract not initialized');
    }

    try {
      const owner = await this.propertyRegistry.get_property_owner(uint256.bnToUint256(tokenId));
      const metadata = await this.propertyRegistry.get_property_metadata(uint256.bnToUint256(tokenId));
      const price = await this.propertyRegistry.get_property_price(uint256.bnToUint256(tokenId));
      const verified = await this.propertyRegistry.is_verified(uint256.bnToUint256(tokenId));
      const verificationTimestamp = await this.propertyRegistry.get_verification_timestamp(uint256.bnToUint256(tokenId));

      return {
        owner,
        metadata,
        price: uint256.uint256ToBN(price).toString(),
        verified,
        verificationTimestamp: verificationTimestamp.toString()
      };
    } catch (error) {
      console.error('Error getting property details:', error);
      throw error;
    }
  }

  /**
   * Get property ownership history
   */
  async getPropertyHistory(tokenId) {
    if (!this.propertyRegistry) {
      throw new Error('PropertyRegistry contract not initialized');
    }

    try {
      const history = await this.propertyRegistry.get_property_history(uint256.bnToUint256(tokenId));
      return history;
    } catch (error) {
      console.error('Error getting property history:', error);
      throw error;
    }
  }

  // ============ Escrow Functions ============

  /**
   * Create an escrow for property transaction
   */
  async createEscrow(propertyTokenId, buyerAddress, amount, escrowType, releaseConditions) {
    if (!this.escrow) {
      throw new Error('Escrow contract not initialized');
    }

    try {
      const result = await this.escrow.create_escrow(
        uint256.bnToUint256(propertyTokenId),
        buyerAddress,
        uint256.bnToUint256(amount),
        escrowType, // 0: booking, 1: deposit, 2: full payment
        releaseConditions
      );

      await this.provider.waitForTransaction(result.transaction_hash);

      return {
        success: true,
        transactionHash: result.transaction_hash,
        escrowId: result.escrow_id
      };
    } catch (error) {
      console.error('Error creating escrow:', error);
      throw error;
    }
  }

  /**
   * Get escrow status
   */
  async getEscrowStatus(escrowId) {
    if (!this.escrow) {
      throw new Error('Escrow contract not initialized');
    }

    try {
      const status = await this.escrow.get_escrow_status(uint256.bnToUint256(escrowId));
      const amount = await this.escrow.get_escrow_amount(uint256.bnToUint256(escrowId));
      const parties = await this.escrow.get_escrow_parties(uint256.bnToUint256(escrowId));
      const disputed = await this.escrow.is_disputed(uint256.bnToUint256(escrowId));

      return {
        status, // 0: pending, 1: funded, 2: released, 3: refunded, 4: disputed
        amount: uint256.uint256ToBN(amount).toString(),
        seller: parties[0],
        buyer: parties[1],
        disputed
      };
    } catch (error) {
      console.error('Error getting escrow status:', error);
      throw error;
    }
  }

  // ============ Reputation Functions ============

  /**
   * Register an agent
   */
  async registerAgent(agentAddress, metadataUri) {
    if (!this.reputation) {
      throw new Error('Reputation contract not initialized');
    }

    try {
      const result = await this.reputation.register_agent(
        agentAddress,
        metadataUri
      );

      await this.provider.waitForTransaction(result.transaction_hash);

      return {
        success: true,
        transactionHash: result.transaction_hash
      };
    } catch (error) {
      console.error('Error registering agent:', error);
      throw error;
    }
  }

  /**
   * Add a review for an agent
   */
  async addReview(agentAddress, reviewerAddress, rating, propertyTokenId, reviewHash) {
    if (!this.reputation) {
      throw new Error('Reputation contract not initialized');
    }

    try {
      const result = await this.reputation.add_review(
        agentAddress,
        reviewerAddress,
        rating, // 1-5
        uint256.bnToUint256(propertyTokenId),
        reviewHash
      );

      await this.provider.waitForTransaction(result.transaction_hash);

      return {
        success: true,
        transactionHash: result.transaction_hash
      };
    } catch (error) {
      console.error('Error adding review:', error);
      throw error;
    }
  }

  /**
   * Get agent reputation score
   */
  async getAgentReputation(agentAddress) {
    if (!this.reputation) {
      throw new Error('Reputation contract not initialized');
    }

    try {
      const score = await this.reputation.get_agent_score(agentAddress);
      const reviewCount = await this.reputation.get_agent_review_count(agentAddress);
      const verified = await this.reputation.is_agent_verified(agentAddress);
      const fraudReports = await this.reputation.get_fraud_reports(agentAddress);

      return {
        score: uint256.uint256ToBN(score).toString(), // Score * 100 (e.g., 450 = 4.50)
        reviewCount: uint256.uint256ToBN(reviewCount).toString(),
        verified,
        fraudReports: uint256.uint256ToBN(fraudReports).toString()
      };
    } catch (error) {
      console.error('Error getting agent reputation:', error);
      throw error;
    }
  }

  /**
   * Report fraud
   */
  async reportFraud(agentAddress, propertyTokenId, evidenceHash) {
    if (!this.reputation) {
      throw new Error('Reputation contract not initialized');
    }

    try {
      const result = await this.reputation.report_fraud(
        agentAddress,
        uint256.bnToUint256(propertyTokenId),
        evidenceHash
      );

      await this.provider.waitForTransaction(result.transaction_hash);

      return {
        success: true,
        transactionHash: result.transaction_hash
      };
    } catch (error) {
      console.error('Error reporting fraud:', error);
      throw error;
    }
  }

  // ============ Event Listeners ============

  /**
   * Listen to PropertyMinted events
   */
  async listenToPropertyMintedEvents(callback) {
    if (!this.propertyRegistry) {
      throw new Error('PropertyRegistry contract not initialized');
    }

    // Implementation depends on Starknet event subscription
    // This is a placeholder for the actual implementation
    console.log('Listening to PropertyMinted events...');
  }

  /**
   * Listen to all contract events
   */
  async startEventListeners(callbacks) {
    // Start listening to all relevant events
    // callbacks should be an object with event handlers
    console.log('Starting Starknet event listeners...');
  }
}

module.exports = new StarknetService();
