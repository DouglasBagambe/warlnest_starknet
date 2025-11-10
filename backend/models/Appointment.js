const mongoose = require("mongoose");

const AppointmentSchema = new mongoose.Schema({
  propertyId: { type: mongoose.Schema.Types.ObjectId, ref: "Property" },
  name: String,
  email: String,
  phone: String,
  appointmentTime: Date,
  duration: String,
  purpose: String,
});

module.exports = mongoose.model("Appointment", AppointmentSchema);
