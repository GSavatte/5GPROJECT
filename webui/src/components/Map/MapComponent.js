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
  let fileInput = null;

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

  const handleExportNetwork = () => {
    const exportData = {
      metadata: {
        exportDate: new Date().toISOString(),
        totalUEs: ues.length,
        totalGNBs: gnbs.length,
        description: "Snapshot des positions du réseau 5G"
      },
      gnbs: gnbs,
      subscribers: ues
    };

    const jsonString = JSON.stringify(exportData, null, 2);
    
    const blob = new Blob([jsonString], { type: 'application/json' });
    
    const downloadUrl = URL.createObjectURL(blob);
    
    const link = document.createElement('a');
    link.href = downloadUrl;
    
    const dateStr = new Date().toISOString().slice(0, 10);
    link.download = `reseau_5g_${dateStr}.json`;
    
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(downloadUrl);
  };

  const handleImportNetwork = (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        const importedData = JSON.parse(e.target.result);

        const response = await fetch('/api/import-network', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(importedData)
        });

        if (response.ok) {
          alert("✅ Configuration importée avec succès dans la base de données ! Le script Bash va continuer.");
        } else {
          const errorData = await response.json();
          alert(`❌ Erreur côté serveur : ${errorData.error}`);
        }

      } catch (error) {
        alert("❌ Erreur : Le fichier JSON est invalide ou corrompu.");
        console.error(error);
      }
      
      event.target.value = null; 
    };
    reader.readAsText(file);
  };



  return (
    <div style={{ height: '100%', width: '100%' }}>
      <Head>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.1/dist/leaflet.css" />
      </Head>

      <input 
        type="file" 
        accept=".json" 
        ref={(inputElement) => { fileInput = inputElement; }} 
        onChange={handleImportNetwork} 
        style={{ display: 'none' }} 
      />

      <div style={{ position: 'absolute', top: '80px', right: '20px', zIndex: 1000, display: 'flex', gap: '10px' }}>
        {/* LE BOUTON D'IMPORT */}
        <button 
          onClick={() => {
            if (fileInput) fileInput.click();
          }}
          style={{
            backgroundColor: '#fff',
            color: '#9e0606', border: 'none', padding: '12px 20px',
            borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer',
            border: '2px solid #9e0606',
            boxShadow: '0 4px 6px rgba(0,0,0,0.3)'
          }}
        >
          Importer (JSON)
        </button>

        <button
          onClick={handleExportNetwork}
          style={{
            backgroundColor: '#9e0606',
            color: 'white', border: 'none', padding: '12px 20px',
            borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer',
            boxShadow: '0 4px 6px rgba(0,0,0,0.3)'
          }}
          >Exporter le réseau</button>
      </div>
      
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
              zIndexOffset={1000}
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