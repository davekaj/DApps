var path = require('path');
var webpack = require('webpack');
const fileName = `dist.js`;

module.exports = {
  entry: `./index.js`,
  output: { path: `${__dirname}`, filename: `${fileName}` },
  module: {
    loaders: [
      {
        test: /.jsx?$/,
        loader: 'babel',
        exclude: /node_modules/,
        query: {
          presets: ['es2015', 'react', 'stage-0']
        }
      },
      {
        test : /.json?$/,
        loader : "json-loader"
      },
      {
        test: /\.svg$/,
        loader: 'react-svg?es5=1'
      },
      {
        test: /\.less$/,
        loader: "style-loader!css-loader!less-loader"
      },
      { test: /\.(png|jpg)$/, loader: 'url-loader?limit=8192' },
      {
        test: /\.scss$/,
        loaders: ["style", "css", "sass"]
      },
      {
        test: /\.(png|jpe?g|gif|woff|woff2|ttf|eot|ico)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file-loader?name=fonts/[name].[hash].[ext]?'
      },
      {
        test: /\.css?$/,
        loader: "style-loader!css-loader!"
      },
      {
        test: /\.(png|jpg)$/,
        loader: "file-loader?name=images/[name].[ext]"
      }
    ],
    plugins: [
      new webpack.DefinePlugin({
          'process.env.NODE_ENV': JSON.stringify('development'),
      })
    ]
  },
  resolve : {
    alias : {}
  }
};
