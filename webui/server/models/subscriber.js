const mongoose = require('mongoose');
const Schema = mongoose.Schema;
require('mongoose-long')(mongoose);

const Subscriber = new Schema({

  schema_version: {
    $type: Number,
    default: 1  // Current Schema Version
  },

  alias: String,

  position: {
    latitude: { $type: Number, required: true, default: 48.116074 },
    longitude: { $type: Number, required: true, default: -1.63841 }
  },

  destination: {
    latitude: { $type: Number, required: true, default: 48.116074 },
    longitude: { $type: Number, required: true, default: -1.63841 }
  },

  speed: { $type: Number, default: 5 },
  isMoving: { $type: Boolean, default: false },

  current_gnb: { $type: String, default: '' },
  target_gnb: { $type: String, default: '' },
  handover_status: { 
    $type: String, 
    enum: ['idle', 'pending', 'completed'], 
    default: 'idle' 
  },

  imsi: { $type: String, unique: true, required: true },

  msisdn: [ String ],
  imeisv: [ String ],
  mme_host: [ String ],
  mme_realm: [ String ],
  purge_flag: [ Boolean ],

  security: {
    k: String,
    op: String,
    opc: String,
    amf: String,
    rand: String,
    sqn: Schema.Types.Long
  },

  ambr: {
    downlink: { value: Number, unit: Number },
    uplink: { value: Number, unit: Number }
  },

  slice: [{
    sst: { $type: Number, required: true },
    sd: String,
    default_indicator: Boolean,
    session: [{
      name: { $type: String, required: true }, // DNN or APN
      type: Number,
      qos: {
        index: Number, // 5QI or QCI
        arp: {
          priority_level: Number,
          pre_emption_capability: Number,
          pre_emption_vulnerability: Number,
        }
      },
      ambr: {
        downlink: { value: Number, unit: Number },
        uplink: { value: Number, unit: Number }
      },
      ue: {
        ipv4: String,
        ipv6: String
      },
      smf: {
        ipv4: String,
        ipv6: String
      },
      pcc_rule: [{
        flow: [{
          direction: Number,
          description: String
        }],
        qos: {
          index: Number, // 5QI or QCI
          arp: {
            priority_level: Number,
            pre_emption_capability: Number,
            pre_emption_vulnerability: Number,
          },
          mbr: {
            downlink: { value: Number, unit: Number },
            uplink: { value: Number, unit: Number }
          },
          gbr: {
            downlink: { value: Number, unit: Number },
            uplink: { value: Number, unit: Number }
          },
        },
      }]
    }]
  }],

  access_restriction_data: {
    $type: Number,
    default: 32 // Handover to Non-3GPP Access Not Allowed
  },
  subscriber_status: {
    $type: Number,
    default: 0  // Service Granted
  },
  operator_determined_barring: {
    $type: Number,
    default: 0 // No barring
  },
  network_access_mode: {
    $type: Number,
    default: 0 // Packet and Circuit
  },
  subscribed_rau_tau_timer: {
    $type: Number,
    default: 12 // minites
  }

}, { typeKey: '$type' });

module.exports = mongoose.model('Subscriber', Subscriber);
