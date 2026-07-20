import React, { Component } from 'react';
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
  '#73bf69', '#fade2a', '#5794f2', '#ff9830', '#f2495c', 
  '#b877d9', '#37872d', '#e0b400', '#1f60c4', '#fa6400', 
  '#c4162a', '#8f3bb8', '#c8f2c2', '#fff899', '#c0d8ff', 
  '#ffcb7d', '#ffa6b0', '#deb6f2'
];

class MapComponent extends Component {
  constructor(props) {
    super(props);
    
    this.state = {
      isDeploying: false
    };

    this.fileInput = null;
  }

  findClosestGnb = (ueLat, ueLng) => {
    const { gnbs = [] } = this.props;
    
    if (gnbs.length === 0) return null;
    
    return gnbs.reduce((closest, current) => {
      const distCurrent = Math.pow(current.location.lat - ueLat, 2) + Math.pow(current.location.lng - ueLng, 2);
      const distClosest = Math.pow(closest.location.lat - ueLat, 2) + Math.pow(closest.location.lng - ueLng, 2);
      
      return distCurrent < distClosest ? current : closest;
    }, gnbs[0]);
  };

  handleExportNetwork = () => {
    const { gnbs = [], ues = [] } = this.props;
    
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

  handleImportNetwork = (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        const importedData = JSON.parse(e.target.result);

        this.setState({ isDeploying: true });

        const response = await fetch('/api/import-network', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(importedData)
        });

        if (response.ok) {
          const checkStatus = setInterval(async () => {
            try {
              const statusRes = await fetch('/api/status');
              const statusData = await statusRes.json();

              if (statusData.status === 'ready') {
                clearInterval(checkStatus);
                this.setState({ isDeploying: false });
                window.location.reload();
              }
            } catch (err) {
              this.setState({ isDeploying: false });
              console.error("Erreur lors de la vérification du statut :", err);
            }
          }, 2000);
        } else {
          this.setState({ isDeploying: false });
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

  render() {
    const { gnbs = [], ues = [] } = this.props;
    const { isDeploying } = this.state;

    const centerPosition = gnbs.length > 0 
      ? [gnbs[0].location.lat, gnbs[0].location.lng] 
      : [48.116074, -1.63841];

    return (
      <div style={{ height: '100%', width: '100%' }}>
        <Head>
          <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.1/dist/leaflet.css" />
        </Head>

        <input 
          type="file" 
          accept=".json" 
          ref={(inputElement) => { this.fileInput = inputElement; }} 
          onChange={this.handleImportNetwork} 
          style={{ display: 'none' }} 
        />

        <div style={{ position: 'absolute', top: '80px', right: '20px', zIndex: 1000, display: 'flex', gap: '10px' }}>

          <button 
            onClick={() => {
              if (this.fileInput && !isDeploying) this.fileInput.click();
            }}
            disabled={isDeploying}
            style={{
              backgroundColor: '#fff',
              color: '#9e0606', border: 'none', padding: '12px 20px',
              borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer',
              cursor: isDeploying ? 'not-allowed' : 'pointer',
              border: '2px solid #9e0606',
              boxShadow: '0 4px 6px rgba(0,0,0,0.3)',
              opacity: isDeploying ? 0.6 : 1,
              transition: 'all 0.3s ease'
            }}
          >
            {isDeploying ? '⏳ Déploiement en cours...' : 'Importer (JSON)'}
          </button>

          <button
            onClick={this.handleExportNetwork}
            style={{
              backgroundColor: '#9e0606',
              color: 'white', border: 'none', padding: '12px 20px',
              borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer',
              boxShadow: '0 4px 6px rgba(0,0,0,0.3)'
            }}
          >
            Exporter le réseau
          </button>
        </div>
        
        <Map center={centerPosition} zoom={15} style={{ height: '100%', width: '100%' }}>
          <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />

          {gnbs.map((gnb, index) => {
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

          {ues.map((ue, index) => {
            const lat = (ue.position && ue.position.latitude) ? ue.position.latitude : undefined;
            const lng = (ue.position && ue.position.longitude) ? ue.position.longitude : undefined;

            if (lat === undefined || lng === undefined) return null;

            const attachedGnb = this.findClosestGnb(lat, lng);

            let ueColor = 'gray'; 
            if (attachedGnb) {
              const colorIndex = (parseInt(attachedGnb.gnbId, 10) - 1) % GNB_COLORS.length;
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
};

export default MapComponent;