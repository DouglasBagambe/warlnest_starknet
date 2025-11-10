# Property Rent Backend

This is the backend server for the Property Rent application, built with Node.js, Express, and MongoDB.

## Setup

1. Install dependencies:

```bash
npm install
```

2. Create a `.env` file with:

```
PORT=3000
MONGO_URI=mongodb://localhost:27017/property_rent
```

3. Start MongoDB (if not running):

```bash
mongod
```

4. Start the server:

```bash
# Development mode
npm run dev

# Production mode
npm start
```

## API Endpoints

### Properties

- `GET /api/properties` - Get all properties
- `GET /api/properties/featured` - Get featured properties
- `GET /api/properties/:id` - Get property by ID
- `POST /api/properties` - Add a new property

### Appointments

- `POST /api/appointments` - Create a new appointment
- `GET /api/appointments/property/:propertyId` - Get appointments for a property

## Sample Property Data

Use Postman or cURL to POST to `http://localhost:3000/api/properties` with JSON like:

```json
{
  "title": "Modern Apartment",
  "description": "A beautiful apartment in Kampala.",
  "images": ["https://example.com/image1.jpg"],
  "videoTour": "",
  "location": "Kampala",
  "type": "apartment",
  "purpose": "rent",
  "price": 500,
  "appointmentFee": 20,
  "size": {
    "bedrooms": 2,
    "bathrooms": 1,
    "dimensions": "80 sqm"
  },
  "tags": ["new"],
  "amenities": ["wifi", "parking"],
  "agent": {
    "name": "Jane Doe",
    "role": "Agent",
    "photo": "https://example.com/agent.jpg",
    "phone": "123456789",
    "email": "jane@example.com"
  },
  "isActive": true,
  "isFeatured": true
}
```

You can also use MongoDB Compass for GUI data entry if you prefer.
