// components/Map/MapComponent.js
import React from 'react';
import { Map, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import Head from 'next/head';

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconUrl: 'https://unpkg.com/leaflet@1.3.1/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.3.1/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.3.1/dist/images/marker-shadow.png',
});

const colorIcon = (colorHex) => {
  return new L.DivIcon({
    className: `custom-marker-${colorHex.replace('#', '')}`,
    html: `<svg width="25" height="41" viewBox="0 0 25 41" xmlns="http://www.w3.org/2000/svg" style="filter: drop-shadow(1px 1px 2px rgba(0,0,0,0.4));">
             <path d="M12.5 0C5.59644 0 0 5.59644 0 12.5C0 21.875 12.5 41 12.5 41C12.5 41 25 21.875 25 12.5C25 5.59644 19.4036 0 12.5 0Z" fill="${colorHex}"/>
             <circle cx="12.5" cy="12.5" r="4" fill="white"/>
           </svg>`,
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34]
  });
};

const GNB_COLORS = [
  '#e6194b',
  '#3cb44b', 
  '#ffe119', 
  '#4363d8', 
  '#f58231', 
  '#911eb4', 
  '#42d4f4', 
  '#f032e6', 
  '#bcf60c', 
  '#fabed4', 
  '#008080',
  '#e6beff',
  '#9a6324',
  '#fffac8',
  '#800000',
  '#aaffc3'
];

const MapComponent = ({ gnbs = [], ues = [] }) => {

  const centerPosition = gnbs.length > 0 
    ? [gnbs[0].location.lat, gnbs[0].location.lng] 
    : [48.116074, -1.63841];

  const findClosestGnb = (ueLat, ueLng) => {
    if (gnbs.length === 0) return null;
    
    return gnbs.reduce((closest, current) => {
      const distCurrent = Math.pow(current.location.lat - ueLat, 2) + Math.pow(current.location.lng - ueLng, 2);
      const distClosest = Math.pow(closest.location.lat - ueLat, 2) + Math.pow(closest.location.lng - ueLng, 2);
      
      return distCurrent < distClosest ? current : closest;
    }, gnbs[0]);
  };

  return (
    <div style={{ height: '100%', width: '100%' }}>
      <Head>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.1/dist/leaflet.css" />
      </Head>
      
      <Map center={centerPosition} zoom={15} style={{ height: '100%', width: '100%' }}>
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />

        {/* 1. Rendu des gNBs */}
        {gnbs.map((gnb, index) => {
          const colorIndex = gnb.gnbId ? (parseInt(gnb.gnbId, 10) % GNB_COLORS.length) : index % GNB_COLORS.length;
          const gnbColor = GNB_COLORS[colorIndex];

          return (
            <Marker 
              key={`gnb-${gnb._id || index}`} 
              position={[gnb.location.lat, gnb.location.lng]}
              icon={colorIcon('#9e0606')}
            >
              <Popup>
                <strong>{gnb.name || `gNB ${gnb.gnbId}`}</strong>
              </Popup>
            </Marker>
          );
        })}

        {/* 2. Rendu des UEs */}
        {ues.map((ue, index) => {
          const lat = (ue.position && ue.position.latitude) ? ue.position.latitude : undefined;
          const lng = (ue.position && ue.position.longitude) ? ue.position.longitude : undefined;

          if (lat === undefined || lng === undefined) return null;

          const attachedGnb = findClosestGnb(lat, lng);

          let ueColor = 'gray'; 
          if (attachedGnb) {
            const colorIndex = parseInt(attachedGnb.gnbId, 10) % GNB_COLORS.length;
            ueColor = GNB_COLORS[colorIndex];
          }

          return (
            <Marker 
              key={`ue-${ue._id || index}`}
              position={[lat, lng]}
              icon={colorIcon(ueColor)}
            >
              <Popup>
                <div style={{ color: '#333', minWidth: '150px' }}>
                  <strong style={{ display: 'block', marginBottom: '5px' }}>
                    UE: {String(ue.imsi || 'IMSI inconnu')}
                  </strong>
                  
                  {attachedGnb ? (
                    <small style={{ color: '#555' }}>
                      Connecté à : <strong>{String(attachedGnb.name || attachedGnb.gnbId || 'gNB inconnu')}</strong>
                    </small>
                  ) : (
                    <small style={{ color: '#d9534f' }}>
                      ⚠️ Erreur de récupération du gNB le plus proche
                    </small>
                  )}
                </div>
              </Popup>
            </Marker>
          );
        })}

      </Map>
    </div>
  );
};

export default MapComponent;