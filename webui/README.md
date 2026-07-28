# WebUI

This directory contains the web interface used to manage and visualize the network (subscribers, gNBs, live map). It is based on the stock [Open5GS WebUI](https://open5gs.org/), with a few additions on top to support this project's dynamic gNB/UE simulation and mobility features.

## What's been changed from stock Open5GS WebUI

- **`server/index.js`** — added extra routes on top of the default ones (gNB data, mobility-related endpoints) to expose what the new frontend components need.
- **`server/models/`** — extended the existing Mongoose models (notably `gnb.js` and `subscriber.js`) with the extra fields used by this project (e.g. gNB location, UE mobility state).
- **`server/mobilityEngine.js`** — new file, not part of stock Open5GS. Runs the mobility simulation loop described in the main [README](../README.md#advanced-features).
- **`src/components/Map/`** — new component, not part of stock Open5GS. Renders the live map (gNBs and UEs) using `MapComponent.js`, with `color_icon.js` handling marker styling.

Everything else (`.next/`, `pages/`, `src/containers/`, `src/helpers/`, `src/modules/`, `src/components/Account`, `Base`, `Profile`, `Shared`, `Subscriber`, auth/db routes, config files) is unchanged from the original Open5GS WebUI and follows its standard Next.js structure.

## Structure

```text
webui/
├── pages/                    # Next.js pages (routing)
├── server/
│   ├── models/                # Mongoose models (DB schema)
│   │   ├── account.js
│   │   ├── gnb.js               # extended: gNB location & metadata
│   │   ├── profile.js
│   │   └── subscriber.js        # extended: UE mobility fields
│   ├── routes/                # Express routes
│   │   ├── auth.js
│   │   ├── db.js
│   │   └── index.js
│   ├── index.js               # server entry point — new routes added here
│   └── mobilityEngine.js      # new — drives simulated UE movement & handover triggers
└── src/
    ├── components/
    │   ├── Account/, Base/, Profile/, Shared/, Subscriber/   # stock Open5GS
    │   └── Map/                # new — live map of gNBs and UEs
    │       ├── MapComponent.js
    │       └── color_icon.js
    ├── containers/
    ├── helpers/
    └── modules/
```

## Running it

The WebUI is started as part of the main project's `start.sh` — see the main [README](../README.md#getting-started). It isn't meant to be run standalone outside the Docker stack, since it depends on the shared MongoDB instance and network defined there.