import {
  fetchCollection,
  fetchDocument,
  createDocument,
  updateDocument,
  deleteDocument
} from './actions'

export const MODEL = 'gnb';
export const URL = '/Gnb';

export const fetchGnbs = (params = {}) => {
  return fetchCollection(MODEL, URL, params, { idProperty: 'gnbId' });
}

export const fetchGnb = (id, params = {}) => {
  return fetchDocument(MODEL, id, `${URL}/${id}`, params, { idProperty: 'gnbId' });
}

export const createGnb = (params = {}, data = {}) => {
  return createDocument(MODEL, URL, params, data, { idProperty: 'gnbId' });
}

export const updateGnb = (id, params = {}, data = {}) => {
  return updateDocument(MODEL, id, `${URL}/${id}`, params, data, { idProperty: 'gnbId' });
}

export const deleteGnb = (id, params = {}) => {
  return deleteDocument(MODEL, id, `${URL}/${id}`, params, { idProperty: 'gnbId' });
}
