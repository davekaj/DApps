import * as Reducers from './reducers';
console.log('Reducers', Reducers)
import { createStore, applyMiddleware, combineReducers, compose } from 'redux';
import thunk from 'redux-thunk';
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
const reducer = combineReducers({ ...Reducers,});

const store = createStore(reducer, composeEnhancers(applyMiddleware(thunk)));
module.exports = {
  store: store,
};
