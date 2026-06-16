import { Component } from 'react';

class Collection extends Component {
  constructor(props) {
    super(props);
    this.state = { MapComponent: null };
  }

  componentDidMount() {
    const MapComponent = require('../../components/Map/MapComponent').default;
    this.setState({ MapComponent });
  }

  render() {
    const { MapComponent } = this.state;

    return (
      <div style={{ padding: '20px', height: '100%', width: '100%' }}>
        <h2 style={{ marginBottom: '20px' }}>Topologie du Réseau 5G</h2>
        <div style={{ height: '70vh', width: '100%', border: '1px solid #ddd', borderRadius: '4px' }}>
          {MapComponent ? <MapComponent /> : <p style={{ padding: '20px' }}>Chargement de la carte...</p>}
        </div>
      </div>
    );
  }
}

export default Collection;