import React from 'react';
import { render } from 'react-dom';
import { Provider } from 'react-redux';
import { store } from './store';
import {
  MetaPay,
} from './components';


render(
  <Provider store={store}>
    <MetaPay />
  </Provider>, document.getElementById('app'));
