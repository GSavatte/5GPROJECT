// server/models/gnb.js
const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const gnbSchema = new Schema({
    schema_version: {
        $type: Number,
        default: 1
    },

    gnbId: { $type: Number, required: true, unique: true },
    name: { $type: String, required: true },
    location: {
        lat: { $type: Number, required: true },
        lng: { $type: Number, required: true }
    },
    supportedSlices: [{
        sst: { $type: Number, required: true },
        sd: { $type: Number, required: true }
    }]
}, { timestamps: true, typeKey: '$type' });

module.exports = mongoose.model('Gnb', gnbSchema);