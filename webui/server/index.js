process.env.DB_URI = process.env.DB_URI || 'mongodb://localhost/open5gs';

const _hostname = process.env.HOSTNAME || 'localhost';
const port = process.env.PORT || 9999;

const co = require('co');
const next = require('next');
const fs = require('fs');

const dev = process.env.NODE_ENV !== 'production';
const app = next({ dev });
const handle = app.getRequestHandler();

const express = require('express');
const bodyParser = require('body-parser');
const methodOverride = require('method-override');
const morgan = require('morgan');
const session = require('express-session');

const mongoose = require('mongoose');
const MongoStore = require('connect-mongo');

const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;

const csrf = require('lusca').csrf();
const secret = process.env.SECRET_KEY || 'change-me';

const api = require('./routes');

const Account = require('./models/account.js');
const Subscriber = require('./models/subscriber');
const Gnb = require('./models/gnb');

co(function* () {
  yield app.prepare();

  mongoose.Promise = global.Promise;
  if (dev) {
    mongoose.set('debug', true);
  }
  const db = yield mongoose.connect(process.env.DB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 1000
    /* other options */
  })

  if (dev) {
    Account.count((err, count) => {
      if (err) {
        console.error(err);
        throw err;
      }

      if (!count) {
        const newAccount = new Account();
        newAccount.username = 'admin';
        newAccount.roles = [ 'admin' ];
        Account.register(newAccount, '1423', err => {
          if (err) {
            console.error(err);
            throw err;
          }
        })
      }
    })
  }

  const server = express();

  server.set('etag', false);
  server.use((req, res, next) => {
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
    next();
  });
  
  server.use(bodyParser.json({ limit: '50mb' }));
  server.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));
  server.use(methodOverride());

  server.use(session({
    secret: secret,
    store: MongoStore.create({
      mongoUrl: process.env.DB_URI,
      ttl: 60 * 60 * 24 * 7 * 2
    }),
    resave: false,
    rolling: true,
    saveUninitialized: true,
    httpOnly: true,
    cookie: {
      maxAge: 1000 * 60 * 60 * 24 * 7 * 2  // 2 weeks
    }
  }));

  server.use((req, res, next) => {
    req.db = db;
    next();
  })

  server.get('/api/status', (req, res) => {
    try {
      const statusData = fs.readFileSync('/shared_flags/status.json', 'utf8');
      res.status(200).json(JSON.parse(statusData));
    } catch (error) {
      res.status(200).json({ status: "ready" });
    }
  });

  server.post('/api/import-network', async (req, res) => {
    try {
      const { subscribers, gnbs } = req.body;
      if (!subscribers || !gnbs) return res.status(400).json({ error: "Format invalide" });

      const sanitizeData = (docs) => docs.map(doc => {
        const { _id, __v, createdAt, updatedAt, ...cleanDoc } = doc;
        return cleanDoc;
      });

      const cleanSubscribers = sanitizeData(subscribers);
      const cleanGnbs = sanitizeData(gnbs);

      console.log("🧹 Suppression des anciennes configurations en mode Raw...");
      await mongoose.connection.db.collection('subscribers').deleteMany({});
      await mongoose.connection.db.collection('gnbs').deleteMany({});

      console.log(`📥 Importation de ${cleanSubscribers.length} UEs et ${cleanGnbs.length} gNBs...`);
      
      if (cleanSubscribers.length > 0) {
        await mongoose.connection.db.collection('subscribers').insertMany(cleanSubscribers);
      }
      if (cleanGnbs.length > 0) {
        await mongoose.connection.db.collection('gnbs').insertMany(cleanGnbs);
      }

      console.log("Seding redeploy signal to start.sh...");

      try {
        fs.writeFileSync('/shared_flags/redeploy.flag', 'go');
      } catch (err) {
        console.error("❌ Erreur lors de la création du fichier de signalisation :", err);
        return res.status(500).json({ error: "Erreur serveur lors de la création du fichier de signalisation" });
      }

      res.status(200).json({ message: "Base de données mise à jour. Redémarrage physique en cours..." });
    } catch (error) {
      console.error("❌ Erreur d'import :", error);
      res.status(500).json({ error: "Erreur serveur" });
    }
  });

  server.use(csrf);

  server.use(passport.initialize());
  server.use(passport.session());

  passport.use(new LocalStrategy(Account.authenticate()));
  passport.serializeUser(Account.serializeUser());
  passport.deserializeUser(Account.deserializeUser());

  server.use('/api', api);

  server.get('*', (req, res) => {
    return handle(req, res);
  });

  if (dev) {
    server.use(morgan('tiny'));
  }

  server.listen(port, _hostname, err => {
    if (err) throw err;
    console.log('> Ready on http://' + _hostname + ':' + port);
  });
})
.catch(error => console.error(error.stack));
