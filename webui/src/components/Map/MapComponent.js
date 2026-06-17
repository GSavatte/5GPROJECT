// components/Map/MapComponent.js
import React from 'react';
import { Map, TileLayer, Marker, Popup, Polyline } from 'react-leaflet';
import L from 'leaflet';
import Head from 'next/head';

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconUrl: 'https://unpkg.com/leaflet@1.3.1/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.3.1/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.3.1/dist/images/marker-shadow.png',
});

const gnbIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34]
});

const ueIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34]
});

const MapComponent = ({ gnbs = [], ues = [] }) => {

  const centerPosition = gnbs.length > 0 
    ? [gnbs[0].location.lat, gnbs[0].location.lng] 
    : [48.116074, -1.63841];

  return (
    <div style={{ height: '100%', width: '100%' }}>
      <Head>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.1/dist/leaflet.css" />
      </Head>
      
      <Map center={centerPosition} zoom={15} style={{ height: '100%', width: '100%' }}>
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        
        {gnbs.map((gnb, index) => (
          <Marker 
            key={`gnb-${gnb._id || index}`} 
            position={[gnb.location.lat, gnb.location.lng]}
            icon={gnbIcon}
          >
            <Popup>
              <strong>{gnb.name || `gNB ${gnb.gnbId}`}</strong>
            </Popup>
          </Marker>
        ))}

        {ues.map((ue, index) => (
          <Marker 
            key={`ue-${ue._id || index}`} 
            position={[ue.position.latitude, ue.position.longitude]}
            icon={ueIcon}
          >
            <Popup>
              <strong>UE: {ue.imsi}</strong>
            </Popup>
          </Marker>
        ))}

        {ues.map((ue, index) => {
          if (ue.connectedGnbId) {
            const connectedGnb = gnbs.find(gnb => gnb.gnbId === ue.connectedGnbId);
            if (connectedGnb) {
              return (
                <Polyline 
                  key={`line-${ue._id || index}`} 
                  positions={[
                    [ue.position.latitude, ue.position.longitude],
                    [connectedGnb.location.lat, connectedGnb.location.lng]
                  ]}
                  color="blue"
                />
              );
            }
          }
          return null;
        })}

      </Map>
    </div>
  );
};

export default MapComponent;