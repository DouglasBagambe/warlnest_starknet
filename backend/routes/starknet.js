const express = require('express');
const router = express.Router();
const Property = require('../models/Property');
const starknetService = require('../services/starknet.service');
const crypto = require('crypto');

// ============ Property NFT Routes ============

/**
 * Mint a property as NFT on Starknet
 * POST /api/starknet/properties/:id/mint
 */
router.post('/properties/:id/mint', async (req, res) => {
  try {
    const { id } = req.params;
    const { ownerAddress } = req.body;

    if (!ownerAddress) {
      return res.status(400).json({ message: 'Owner Starknet address required' });
    }

    // Get property from database
    const property = await Property.findById(id);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Check if already minted
    if (property.blockchainTokenId) {
      return res.status(400).json({ 
        message: 'Property already minted',
        tokenId: property.blockchainTokenId 
      });
    }

    // Create metadata URI (could be IPFS in production)
    const metadataUri = `https://api.warlnest.com/metadata/${id}`;
    
    // Convert property type to number
    const propertyTypeMap = {
      'apartment': 0,
      'house': 1,
      'villa': 2,
      'commercial': 3,
      'land': 4,
      'studio': 5
    };
    const propertyType = propertyTypeMap[property.type] || 0;

    // Create location hash
    const locationHash = '0x' + crypto.createHash('sha256')
      .update(property.location + property.region + property.district)
      .digest('hex').substring(0, 62);

    // Mint on Starknet
    const result = await starknetService.mintProperty(
      id,
      ownerAddress,
      metadataUri,
      Math.floor(property.price * 1e18), // Convert to wei equivalent
      propertyType,
      locationHash
    );

    // Update property in database
    property.blockchainTokenId = result.tokenId;
    property.blockchainTxHash = result.transactionHash;
    property.onChain = true;
    property.verified = false; // Will be verified separately
    await property.save();

    res.status(201).json({
      message: 'Property minted successfully',
      tokenId: result.tokenId,
      transactionHash: result.transactionHash,
      property
    });
  } catch (error) {
    console.error('Error minting property:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * Verify a property NFT (admin only)
 * POST /api/starknet/properties/:id/verify
 */
router.post('/properties/:id/verify', async (req, res) => {
  try {
    const { id } = req.params;
    const { verifierAddress } = req.body;

    const property = await Property.findById(id);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    if (!property.blockchainTokenId) {
      return res.status(400).json({ message: 'Property not minted on blockchain' });
    }

    // Verify on Starknet
    const result = await starknetService.verifyProperty(
      property.blockchainTokenId,
      verifierAddress
    );

    // Update property
    property.verified = true;
    property.verificationTxHash = result.transactionHash;
    property.verifiedAt = new Date();
    await property.save();

    res.json({
      message: 'Property verified successfully',
      transactionHash: result.transactionHash,
      property
    });
  } catch (error) {
    console.error('Error verifying property:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * Get property blockchain details
 * GET /api/starknet/properties/:id/blockchain
 */
router.get('/properties/:id/blockchain', async (req, res) => {
  try {
    const { id } = req.params;

    const property = await Property.findById(id);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    if (!property.blockchainTokenId) {
      return res.status(404).json({ message: 'Property not on blockchain' });
    }

    // Get blockchain data
    const blockchainData = await starknetService.getPropertyDetails(property.blockchainTokenId);
    const history = await starknetService.getPropertyHistory(property.blockchainTokenId);

    res.json({
      property: {
        _id: property._id,
        title: property.title,
        blockchainTokenId: property.blockchainTokenId
      },
      blockchain: {
        ...blockchainData,
        history
      }
    });
  } catch (error) {
    console.error('Error getting blockchain details:', error);
    res.status(500).json({ message: error.message });
  }
});

// ============ Escrow Routes ============

/**
 * Create escrow for property booking/deposit
 * POST /api/starknet/escrow/create
 */
router.post('/escrow/create', async (req, res) => {
  try {
    const { propertyId, buyerAddress, amount, escrowType, releaseConditions } = req.body;

    const property = await Property.findById(propertyId);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    if (!property.blockchainTokenId) {
      return res.status(400).json({ message: 'Property not on blockchain' });
    }

    // Escrow types: 0 = booking fee, 1 = deposit, 2 = full payment
    const escrowTypeMap = {
      'booking': 0,
      'deposit': 1,
      'payment': 2
    };

    const result = await starknetService.createEscrow(
      property.blockchainTokenId,
      buyerAddress,
      Math.floor(amount * 1e18), // Convert to wei
      escrowTypeMap[escrowType] || 0,
      releaseConditions || 'Standard release conditions'
    );

    res.status(201).json({
      message: 'Escrow created successfully',
      escrowId: result.escrowId,
      transactionHash: result.transactionHash
    });
  } catch (error) {
    console.error('Error creating escrow:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * Get escrow status
 * GET /api/starknet/escrow/:escrowId
 */
router.get('/escrow/:escrowId', async (req, res) => {
  try {
    const { escrowId } = req.params;

    const escrowData = await starknetService.getEscrowStatus(escrowId);

    const statusMap = {
      0: 'pending',
      1: 'funded',
      2: 'released',
      3: 'refunded',
      4: 'disputed'
    };

    res.json({
      escrowId,
      status: statusMap[escrowData.status] || 'unknown',
      ...escrowData
    });
  } catch (error) {
    console.error('Error getting escrow status:', error);
    res.status(500).json({ message: error.message });
  }
});

// ============ Reputation Routes ============

/**
 * Register agent on blockchain
 * POST /api/starknet/agents/register
 */
router.post('/agents/register', async (req, res) => {
  try {
    const { agentAddress, metadata } = req.body;

    if (!agentAddress) {
      return res.status(400).json({ message: 'Agent address required' });
    }

    // Create metadata URI
    const metadataUri = `https://api.warlnest.com/agents/${agentAddress}/metadata`;

    const result = await starknetService.registerAgent(
      agentAddress,
      metadataUri
    );

    res.status(201).json({
      message: 'Agent registered successfully',
      transactionHash: result.transactionHash
    });
  } catch (error) {
    console.error('Error registering agent:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * Add review for agent
 * POST /api/starknet/agents/:address/review
 */
router.post('/agents/:address/review', async (req, res) => {
  try {
    const { address } = req.params;
    const { reviewerAddress, rating, propertyId, reviewText } = req.body;

    if (!reviewerAddress || !rating || !propertyId) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    if (rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    const property = await Property.findById(propertyId);
    if (!property || !property.blockchainTokenId) {
      return res.status(404).json({ message: 'Property not found on blockchain' });
    }

    // Create review hash
    const reviewHash = '0x' + crypto.createHash('sha256')
      .update(reviewText || '')
      .digest('hex').substring(0, 62);

    const result = await starknetService.addReview(
      address,
      reviewerAddress,
      rating,
      property.blockchainTokenId,
      reviewHash
    );

    res.status(201).json({
      message: 'Review added successfully',
      transactionHash: result.transactionHash
    });
  } catch (error) {
    console.error('Error adding review:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * Get agent reputation
 * GET /api/starknet/agents/:address/reputation
 */
router.get('/agents/:address/reputation', async (req, res) => {
  try {
    const { address } = req.params;

    const reputation = await starknetService.getAgentReputation(address);

    // Convert score to readable format (score is * 100)
    const averageRating = reputation.score / 100;

    res.json({
      agentAddress: address,
      averageRating: averageRating.toFixed(2),
      reviewCount: reputation.reviewCount,
      verified: reputation.verified,
      fraudReports: reputation.fraudReports
    });
  } catch (error) {
    console.error('Error getting agent reputation:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * Report fraud
 * POST /api/starknet/agents/:address/report-fraud
 */
router.post('/agents/:address/report-fraud', async (req, res) => {
  try {
    const { address } = req.params;
    const { propertyId, evidence } = req.body;

    if (!propertyId || !evidence) {
      return res.status(400).json({ message: 'Property ID and evidence required' });
    }

    const property = await Property.findById(propertyId);
    if (!property || !property.blockchainTokenId) {
      return res.status(404).json({ message: 'Property not found on blockchain' });
    }

    // Create evidence hash
    const evidenceHash = '0x' + crypto.createHash('sha256')
      .update(evidence)
      .digest('hex').substring(0, 62);

    const result = await starknetService.reportFraud(
      address,
      property.blockchainTokenId,
      evidenceHash
    );

    res.status(201).json({
      message: 'Fraud reported successfully',
      transactionHash: result.transactionHash
    });
  } catch (error) {
    console.error('Error reporting fraud:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
