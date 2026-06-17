// containers/Map/Collection.js
import { Component } from 'react';
import { connect } from 'react-redux';

import { fetchSubscribers } from 'modules/crud/subscriber';
import { fetchGnbs } from 'modules/crud/gnb';
import { select } from 'modules/crud/selectors';

import { Layout, Spinner } from 'components';

class MapCollection extends Component {
  state = {
    MapComponent: null
  };

  componentWillMount() {
    const { subscribers, gnbs, dispatch } = this.props;

    if (subscribers.needsFetch) {
      dispatch(subscribers.fetch);
    }
    if (gnbs.needsFetch) {
      dispatch(gnbs.fetch);
    }
  }

  componentWillReceiveProps(nextProps) {
    const { subscribers, gnbs } = nextProps;
    const { dispatch } = this.props;

    if (subscribers.needsFetch && !subscribers.isLoading) {
      dispatch(subscribers.fetch);
    }
    if (gnbs.needsFetch && !gnbs.isLoading) {
      dispatch(gnbs.fetch);
    }
  }

  componentDidMount() {
    const MapComponent = require('../../components/Map/MapComponent').default;
    this.setState({ MapComponent });
  }

  render() {
    const { MapComponent } = this.state;
    const { subscribers, gnbs } = this.props;

    const isLoading = subscribers.isLoading || gnbs.isLoading;

    return (
      <Layout.Content>
        {isLoading && <Spinner md />}

        {!isLoading && MapComponent && (
          <div style={{ height: '80vh', width: '100%', borderRadius: '4px', overflow: 'hidden' }}>
            <MapComponent 
              ues={subscribers.data} 
              gnbs={gnbs.data} 
            />
          </div>
        )}
      </Layout.Content>
    );
  }
}

export default connect(
  (state) => ({ 
    subscribers: select(fetchSubscribers(), state.crud),
    gnbs: select(fetchGnbs(), state.crud)
  })
)(MapCollection);