const path = require('path');
// const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const urbitrc = require('./urbitrc');
const fs = require('fs');
const util = require('util');
const exec = util.promisify(require('child_process').exec);
const CopyWebpackPlugin = require('copy-webpack-plugin');
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

function copyFile(src, dest) {
  return new Promise((res, rej) =>
    fs.copyFile(src, dest, err => err ? rej(err) : res()));
}

class UrbitShipPlugin {
  constructor(urbitrc) {
    this.piers = urbitrc.URBIT_PIERS;
    this.herb = urbitrc.herb || false;
  }
  apply(compiler) {
    compiler.hooks.afterEmit.tapPromise(
      'UrbitShipPlugin',
      async (compilation) => {
        const src = path.resolve(compiler.options.output.path, 'index.js');
        // uncomment to copy into all piers
        //
        return Promise.all(this.piers.map(pier => {
          const dst = path.resolve(pier, 'app/seer/js/index.js');
          copyFile(src, dst).then(() => {
            if (!this.herb) {
              return;
            }
            pier = pier.split('/');
            const desk = pier.pop();
            return exec(`herb -p hood -d '+hood/commit %${desk}' ${pier.join('/')}`);
          });
        }));
      }
    );
  }
}

let devServer = {
  static: [
      {
        directory: path.join(__dirname, "../dist"),
        publicPath: "/seer/css",
        watch: true
      }
    ],
  hot: true,
  port: 9001,
  host: '0.0.0.0',
  historyApiFallback: false,
};

if (urbitrc.URL) {
  devServer = {
    ...devServer,
    proxy: {
      '/seer/index.js': {
        target: 'http://localhost:9001',
        pathRewrite: (req, path) => '/index.js'
      },
      '/seer/css/index.css': {
        target: 'http://localhost:9001',
        pathRewrite: (req, path) => '/index.css'
      },
      '**': {
        target: urbitrc.URL,
        // ensure proxy doesn't timeout channels
        proxyTimeout: 0
      }
    }
  };
}

module.exports = {
  mode: 'development',
  entry: {
    app: './src/index.js'
  },
  module: {
    rules: [
         {
        test: /\.css$/,
        use: [
          // Creates `style` nodes from JS strings
          {
            loader: MiniCssExtractPlugin.loader,
            options: {
              esModule: false
            }
          },
          // Translates CSS into CommonJS
           {
            loader: "css-loader",
            options: {
              importLoaders: 0,
              modules:false
              // 0 => no loaders (default);
              // 1 => postcss-loader;
              // 2 => postcss-loader, sass-loader
            },
          },

                  ],

                  include: [
                    /\.css$/,
                    path.join(__dirname, "../src/css")                  ],
      },
      {
        test: /\.(j|t)sx?$/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env', '@babel/typescript', '@babel/preset-react'],
                 }
        },
        exclude: /node_modules/
      }
    ]
  },
  resolve: {
    extensions: ['.js', '.ts', '.tsx'],
    fallback: {

    }
  },
  devtool: 'inline-source-map',
  devServer: devServer,
  plugins: [
    new MiniCssExtractPlugin({filename: "index.css"}),

    //new CopyWebpackPlugin({
      //patterns: [


//        { from: '**/*', context: path.resolve(__dirname.split('/').slice(0, __dirname.split("/").length - 1).join("/"), 'urbit'), to: urbitrc.URBIT_PIERS[0] }
      //]
    //}
    //),
    //new UrbitShipPlugin(urbitrc)
  ],
  output: {
    filename: 'index.js',
    chunkFilename: 'index.js',
    path: path.resolve(__dirname, '../dist'),
    publicPath: '/'
  },
  optimization: {
    minimize: false,
    usedExports: true
  }
};
