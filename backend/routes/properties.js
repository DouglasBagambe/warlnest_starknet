const express = require("express");
const router = express.Router();
const Property = require("../models/Property");

// Get all properties with pagination and filters
router.get("/", async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      type,
      purpose,
      minPrice,
      maxPrice,
      location,
      amenities,
      sortBy = "datePosted",
      sortOrder = "desc",
    } = req.query;

    const query = {};

    // Apply filters
    if (type) query.type = type;
    if (purpose) query.purpose = purpose;
    if (location) query.location = { $regex: location, $options: "i" };
    if (minPrice || maxPrice) {
      query.price = {};
      if (minPrice) query.price.$gte = Number(minPrice);
      if (maxPrice) query.price.$lte = Number(maxPrice);
    }
    if (amenities) {
      query.amenities = { $all: amenities.split(",") };
    }

    // Calculate skip value for pagination
    const skip = (Number(page) - 1) * Number(limit);

    // Build sort object
    const sort = {};
    sort[sortBy] = sortOrder === "desc" ? -1 : 1;

    // Execute query with pagination and sorting
    const properties = await Property.find(query)
      .sort(sort)
      .skip(skip)
      .limit(Number(limit));

    // Get total count for pagination
    const total = await Property.countDocuments(query);

    res.json({
      properties,
      currentPage: Number(page),
      totalPages: Math.ceil(total / Number(limit)),
      totalProperties: total,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get featured properties
router.get("/featured", async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const properties = await Property.find({ isFeatured: true })
      .sort({ datePosted: -1 })
      .limit(Number(limit));
    res.json(properties);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get recent properties
router.get("/recent", async (req, res) => {
  try {
    const { limit = 20 } = req.query;
    const properties = await Property.find()
      .sort({ datePosted: -1 })
      .limit(Number(limit));
    res.json(properties);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get property by ID
router.get("/:id", async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Property not found" });
    }

    // Increment views
    property.views += 1;
    await property.save();

    res.json(property);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Add a property
router.post("/", async (req, res) => {
  try {
    const property = new Property(req.body);
    const savedProperty = await property.save();
    res.status(201).json(savedProperty);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Update property
router.patch("/:id", async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Property not found" });
    }

    Object.assign(property, req.body);
    const updatedProperty = await property.save();
    res.json(updatedProperty);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Delete property
router.delete("/:id", async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Property not found" });
    }

    await property.remove();
    res.json({ message: "Property deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Toggle featured status
router.patch("/:id/featured", async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Property not found" });
    }

    property.isFeatured = !property.isFeatured;
    const updatedProperty = await property.save();
    res.json(updatedProperty);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Increment favorites
router.patch("/:id/favorite", async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Property not found" });
    }

    property.favorites += 1;
    const updatedProperty = await property.save();
    res.json(updatedProperty);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Update rating
router.patch("/:id/rating", async (req, res) => {
  try {
    const { rating } = req.body;
    if (rating < 0 || rating > 5) {
      return res
        .status(400)
        .json({ message: "Rating must be between 0 and 5" });
    }

    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Property not found" });
    }

    // Calculate new average rating
    const currentTotal = (property.rating || 0) * (property.reviewCount || 0);
    const newTotal = currentTotal + rating;
    const newCount = (property.reviewCount || 0) + 1;
    property.rating = newTotal / newCount;
    property.reviewCount = newCount;

    const updatedProperty = await property.save();
    res.json(updatedProperty);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

module.exports = router;
