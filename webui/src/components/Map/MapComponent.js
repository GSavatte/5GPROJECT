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

// Position de l'antenne (gNB)
const gnbPosition = [48.1160, -1.6384];

// Positions de tes équipements (UEs)
const ues = [
  { name: 'UE 1 (Smartphone)', position: [48.1175, -1.6400] },
  { name: 'UE 3 (IoT Sensor)', position: [48.1145, -1.6360] }
];

const MapComponent = () => (
  <div style={{ height: '100%', width: '100%' }}>
    <Head>
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.1/dist/leaflet.css" />
    </Head>
    
    <Map 
      center={[48.116074, -1.63841]} 
      zoom={15} 
      style={{ height: '100%', width: '100%' }}
    >
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
      
      {/* Marqueur de l'antenne gNB */}
      <Marker position={gnbPosition}>
        <Popup>
          <strong>gNB_Main_Campus</strong>
        </Popup>
      </Marker>

      {/* 1ère Boucle : Dessiner uniquement les UEs */}
      {ues.map((ue, index) => (
        <Marker key={`marker-${index}`} position={ue.position}>
          <Popup>
            <span>{ue.name}</span>
          </Popup>
        </Marker>
      ))}

      {/* 2ème Boucle : Tracer uniquement les liens radio vers le gNB */}
      {ues.map((ue, index) => (
        <Polyline 
          key={`line-${index}`}
          positions={[gnbPosition, ue.position]} 
          color="#e74c3c" 
          weight={3}      
          opacity={0.8}
          dashArray="10, 10" 
        />
      ))}
    </Map>
  </div>
);

export default MapComponent;