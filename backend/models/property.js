const mongoose = require("mongoose");

const propertySizeSchema = new mongoose.Schema({
  totalArea: {
    type: Number,
    required: true,
  },
  bedrooms: {
    type: Number,
  },
  bathrooms: {
    type: Number,
  },
  parking: {
    type: Number,
  },
  dimensions: {
    type: String,
  },
});

const propertyAgentSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  phone: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
  },
  photo: {
    type: String,
    required: true,
  },
  company: {
    type: String,
  },
  position: {
    type: String,
  },
});

const propertySchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    location: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      enum: ["apartment", "house", "villa", "commercial", "land", "studio"],
      required: true,
    },
    purpose: {
      type: String,
      enum: ["rent", "sale", "shortStay"],
      required: true,
    },
    price: {
      type: Number,
      required: true,
    },
    appointmentFee: {
      type: Number,
      required: true,
    },
    size: {
      type: propertySizeSchema,
      required: true,
    },
    images: [
      {
        type: String,
        required: true,
      },
    ],
    videos: [
      {
        type: String,
        default: [],
      },
    ],
    tags: [
      {
        type: String,
      },
    ],
    amenities: [
      {
        type: String,
      },
    ],
    agent: {
      type: propertyAgentSchema,
      required: true,
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    datePosted: {
      type: Date,
      default: Date.now,
    },
    views: {
      type: Number,
      default: 0,
    },
    favorites: {
      type: Number,
      default: 0,
    },
    rating: {
      type: Number,
      min: 0,
      max: 5,
    },
    reviewCount: {
      type: Number,
      default: 0,
    },
    additionalDetails: {
      type: Map,
      of: mongoose.Schema.Types.Mixed,
    },
    region: {
      type: String,
      required: true,
      index: true,
    },
    district: {
      type: String,
      default: "",
    },
    area: {
      type: String,
      default: "",
    },
    // Blockchain/Starknet fields
    blockchainTokenId: {
      type: String,
      default: null,
      index: true,
    },
    blockchainTxHash: {
      type: String,
      default: null,
    },
    onChain: {
      type: Boolean,
      default: false,
      index: true,
    },
    verified: {
      type: Boolean,
      default: false,
      index: true,
    },
    verificationTxHash: {
      type: String,
      default: null,
    },
    verifiedAt: {
      type: Date,
      default: null,
    },
    ownerWalletAddress: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for better query performance
propertySchema.index({ isFeatured: 1, datePosted: -1 });
propertySchema.index({ datePosted: -1 });
propertySchema.index({ location: 1 });
propertySchema.index({ type: 1, purpose: 1 });
propertySchema.index({ price: 1 });

const Property = mongoose.model("Property", propertySchema);

module.exports = Property;
