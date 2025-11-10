const mongoose = require("mongoose");
const dotenv = require("dotenv");
const Property = require("./models/Property");

dotenv.config();

const sampleProperties = [
  {
    title: "Luxury Villa in Kololo",
    description:
      "Stunning 5-bedroom villa with panoramic views of Kampala. Features a private pool, landscaped gardens, and modern amenities.",
    location: "Kololo, Kampala",
    type: "Villa",
    purpose: "Rent",
    price: 15000000,
    appointmentFee: 50000,
    size: {
      bedrooms: 5,
      bathrooms: 4,
      parking: 3,
      totalArea: 450,
      unit: "sqm",
    },
    images: [
      "https://images.unsplash.com/photo-1613977257363-707ba9348227?w=800&q=80",
      "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80",
      "https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=800&q=80",
    ],
    videos: [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4",
    ],
    tags: ["Luxury", "Pool", "Garden", "Security"],
    amenities: [
      "Swimming Pool",
      "Garden",
      "Security",
      "Parking",
      "Air Conditioning",
      "Backup Power",
    ],
    agent: {
      name: "Sarah Johnson",
      phone: "+256 700 123456",
      email: "sarah@realestate.ug",
      photo:
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80",
    },
    isFeatured: true,
    isActive: true,
    views: 245,
    favorites: 18,
    rating: 4.8,
    reviewCount: 12,
    datePosted: new Date("2024-02-15"),
    region: "Central",
    district: "Kampala",
    area: "Kololo",
  },
  {
    title: "Modern Apartment in Nakasero",
    description:
      "Contemporary 3-bedroom apartment in the heart of Nakasero. Walking distance to restaurants and shopping centers.",
    location: "Nakasero, Kampala",
    type: "Apartment",
    purpose: "Rent",
    price: 8000000,
    appointmentFee: 30000,
    size: {
      bedrooms: 3,
      bathrooms: 2,
      parking: 2,
      totalArea: 180,
      unit: "sqm",
    },
    images: [
      "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80",
      "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80",
      "https://images.unsplash.com/photo-1536376072261-38c75010e6c9?w=800&q=80",
    ],
    videos: [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
    ],
    tags: ["Modern", "Central", "Furnished"],
    amenities: [
      "Security",
      "Parking",
      "Air Conditioning",
      "Backup Power",
      "Gym",
    ],
    agent: {
      name: "David Mukasa",
      phone: "+256 700 234567",
      email: "david@realestate.ug",
      photo:
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80",
    },
    isFeatured: true,
    isActive: true,
    views: 189,
    favorites: 15,
    rating: 4.6,
    reviewCount: 8,
    datePosted: new Date("2024-02-20"),
    region: "Central",
    district: "Kampala",
    area: "Nakasero",
  },
  {
    title: "Commercial Space in Industrial Area",
    description:
      "Prime commercial space suitable for offices or retail. High visibility location with ample parking.",
    location: "Industrial Area, Kampala",
    type: "Commercial",
    purpose: "Rent",
    price: 12000000,
    appointmentFee: 40000,
    size: {
      totalArea: 300,
      unit: "sqm",
      parking: 10,
    },
    images: [
      "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=800&q=80",
      "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800&q=80",
      "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80",
    ],
    videos: [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4",
    ],
    tags: ["Commercial", "Office", "Retail"],
    amenities: ["Parking", "Security", "Backup Power", "Loading Bay"],
    agent: {
      name: "Grace Nakato",
      phone: "+256 700 345678",
      email: "grace@realestate.ug",
      photo:
        "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&q=80",
    },
    isFeatured: false,
    isActive: true,
    views: 156,
    favorites: 12,
    rating: 4.5,
    reviewCount: 6,
    datePosted: new Date("2024-02-25"),
    region: "Central",
    district: "Kampala",
    area: "Industrial Area",
  },
  {
    title: "Family Home in Entebbe",
    description:
      "Spacious 4-bedroom family home with a large garden. Close to schools and the beach.",
    location: "Entebbe",
    type: "House",
    purpose: "Sale",
    price: 850000000,
    appointmentFee: 50000,
    size: {
      bedrooms: 4,
      bathrooms: 3,
      parking: 2,
      totalArea: 350,
      unit: "sqm",
    },
    images: [
      "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80",
      "https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=800&q=80",
      "https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800&q=80",
    ],
    videos: [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4",
    ],
    tags: ["Family", "Garden", "Beach Access"],
    amenities: ["Garden", "Security", "Parking", "Backup Power", "Water Tank"],
    agent: {
      name: "Peter Okello",
      phone: "+256 700 456789",
      email: "peter@realestate.ug",
      photo:
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80",
    },
    isFeatured: true,
    isActive: true,
    views: 234,
    favorites: 20,
    rating: 4.9,
    reviewCount: 15,
    datePosted: new Date("2024-02-28"),
    region: "Central",
    district: "Wakiso",
    area: "Entebbe",
  },
  {
    title: "Studio Apartment in Bugolobi",
    description:
      "Cozy studio apartment perfect for young professionals. Fully furnished with modern amenities.",
    location: "Bugolobi, Kampala",
    type: "Studio",
    purpose: "Rent",
    price: 3500000,
    appointmentFee: 20000,
    size: {
      totalArea: 45,
      unit: "sqm",
    },
    images: [
      "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80",
      "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80",
      "https://images.unsplash.com/photo-1536376072261-38c75010e6c9?w=800&q=80",
    ],
    videos: [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
    ],
    tags: ["Studio", "Furnished", "Modern"],
    amenities: [
      "Furnished",
      "Security",
      "Parking",
      "Air Conditioning",
      "Backup Power",
    ],
    agent: {
      name: "Maria Nalwoga",
      phone: "+256 700 567890",
      email: "maria@realestate.ug",
      photo:
        "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&q=80",
    },
    isFeatured: false,
    isActive: true,
    views: 123,
    favorites: 8,
    rating: 4.3,
    reviewCount: 5,
    datePosted: new Date("2024-03-01"),
    region: "Central",
    district: "Kampala",
    area: "Bugolobi",
  },
];

async function seedDatabase() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB");

    // Clear existing data
    await Property.deleteMany({});
    console.log("Cleared existing properties");

    // Insert new data
    const properties = await Property.insertMany(sampleProperties);
    console.log(`Added ${properties.length} properties to the database`);

    mongoose.connection.close();
  } catch (error) {
    console.error("Error seeding database:", error);
    process.exit(1);
  }
}

seedDatabase();
