const express = require('express');
const router = express.Router();

const restify = require('express-restify-mongoose')

const Subscriber = require('../models/subscriber');
const Profile = require('../models/profile');
const Account = require('../models/account');
const Gnb = require('../models/gnb');

restify.serve(router, Subscriber, {
  prefix: '',
  version: '',
  idProperty: 'imsi'
});

restify.serve(router, Profile, {
  prefix: '',
  version: ''
});

restify.serve(router, Account, {
  prefix: '',
  version: '',
  idProperty: 'username'
});

restify.serve(router, Gnb, {
  prefix: '',
  version: '',
  idProperty: 'gnbId'
});

module.exports = router;