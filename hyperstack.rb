# Hyperstack 2.0 ALPHA Rails Template

##  Commit base rails for we have a full commit history

git :init
git add:    "."
git commit: "-m 'Initial commit: Rails base'"

##  Add the gems

gem 'opal', github: 'janbiedermann/opal', branch: 'es6_import_export'
gem 'opal-autoloader', github: 'janbiedermann/opal-autoloader', branch: 'master'
gem 'hyper-business', github: 'janbiedermann/hyper-business', branch: 'ulysses'
gem 'hyper-gate', github: 'janbiedermann/hyper-gate', branch: 'ulysses'
gem 'hyper-react', github: 'janbiedermann/hyper-react', branch: 'ulysses'
gem 'hyper-resource', github: 'janbiedermann/hyper-resource', branch: 'ulysses'
gem 'hyper-router', github: 'janbiedermann/hyper-router', branch: 'ulysses'
gem 'hyper-store', github: 'janbiedermann/hyper-store', branch: 'ulysses'
gem 'hyper-transport-actioncable', github: 'janbiedermann/hyper-transport-actioncable', branch: 'ulysses'
gem 'hyper-transport-store-redis', github: 'janbiedermann/hyper-transport-store-redis', branch: 'ulysses'
gem 'hyper-transport', github: 'janbiedermann/hyper-transport', branch: 'ulysses'
gem 'opal-webpack-compile-server', github: 'janbiedermann/opal-webpack-compile-server', branch: 'master'

# ----------------------------------- Create the folders

run 'mkdir app/hyperstack'
run 'mkdir app/hyperstack/components'
run 'mkdir app/hyperstack/stores'
run 'mkdir app/hyperstack/models'
run 'mkdir app/hyperstack/operations'

# ----------------------------------- Add .keep files

file 'app/hyperstack/components/.keep', <<-CODE
CODE
file 'app/hyperstack/stores/.keep', <<-CODE
CODE
file 'app/hyperstack/models/.keep', <<-CODE
CODE
file 'app/hyperstack/operations/.keep', <<-CODE
CODE

# ----------------------------------- Create the Hyperstack loader file

file 'app/hyperstack/hyperstack_webpack_loader.rb', <<-CODE
require 'opal'
require 'browser'
require 'browser/delay'
require 'opal-autoloader'
require 'hyper-store'
require 'hyper-react'
require 'hyper-router'
require 'hyper-transport-actioncable'
require 'hyper-transport'
require 'hyper-resource'
require 'hyper-business'
require 'react/auto-import'

require_tree 'components'
require_tree 'stores'
require_tree 'models'
require_tree 'operations'
CODE

# ----------------------------------- Create thyperstack.js

file 'app/javascript/hyperstack.js', <<-CODE
import React from 'react';
import ReactDOM from 'react-dom';
import * as History from 'history';
import * as ReactRouter from 'react-router';
import * as ReactRouterDOM from 'react-router-dom';
import * as ReactRailsUJS from 'react_ujs';
import ActionCable from 'actioncable';

global.React = React;
global.ReactDOM = ReactDOM;
global.History = History;
global.ReactRouter = ReactRouter;
global.ReactRouterDOM = ReactRouterDOM;
global.ReactRailsUJS = ReactRailsUJS;
global.ActionCable = ActionCable;

import init_app from 'hyperstack_webpack_loader.rb';

init_app();
Opal.load('hyperstack_webpack_loader');
if (module.hot) {
    module.hot.accept('./hyperstack.js', function () {
        console.log('Accepting the updated Hyperstack module!');
    })
}
CODE

# ----------------------------------- Create webpack config development.js

file 'config/webpack/development.js', <<-CODE
// require requirements used below
const path = require('path');
const webpack = require('webpack');
const chokidar = require('chokidar'); // for watching app/view
const stringify = require('json-stringify-safe');
const WebSocket = require('ws');
const OpalWebpackResolverPlugin = require('opal-webpack-resolver-plugin'); // to resolve ruby files

module.exports = {
    parallelism: 8,
    context: path.resolve(__dirname, '../..'),
    mode: "development",
    optimization: {
        minimize: false // dont minimize in development, to speed up hot reloads
    },
    performance: {
        maxAssetSize: 20000000, // hyperloop is a lot of code
        maxEntrypointSize: 20000000
    },
    // use this or others below, disable for faster hot reloads
    devtool: 'source-map', // this works well, good compromise between accuracy and performance
    // devtool: 'cheap-eval-source-map', // less accurate
    // devtool: 'inline-source-map', // slowest
    // devtool: 'inline-cheap-source-map',
    entry: {
        app: ['./app/javascript/app.js'] // entrypoint for hyperstack
    },
    output: {
        // webpack-serve keeps the output in memory
        filename: '[name]_development.js',
        path: path.resolve(__dirname, '../../public/packs'),
        publicPath: 'http://localhost:3035/packs/'
    },
    resolve: {
        plugins: [
            // this makes it possible for webpack to find ruby files
            new OpalWebpackResolverPlugin('resolve', 'resolved')
        ]
    },
    plugins: [
        // both for hot reloading
        new webpack.NamedModulesPlugin()
    ],
    module: {
        rules: [
            {
                // loader for .scss files
                // test means "test for for file endings"
                test: /\.scss$/,
                use: [
                    {
                        loader: "style-loader",
                        options: {
                            hmr: true
                        }
                    },
                    {
                        loader: "css-loader",
                        options: {
                            sourceMap: true, // set to false to speed up hot reloads
                            minimize: false // set to false to speed up hot reloads
                        }
                    },
                    {
                        loader: "sass-loader",
                        options: {
                            includePaths: [path.resolve(__dirname, '../../app/assets/stylesheets')],
                            sourceMap: true // set to false to speed up hot reloads
                        }
                    }
                ]
            },
            {
                // loader for .css files
                test: /\.css$/,
                use: [
                    {
                        loader: "style-loader",
                        options: {
                            hmr: true
                        }
                    },
                    {
                        loader: "css-loader",
                        options: {
                            sourceMap: true, // set to false to speed up hot reloads
                            minimize: false // set to false to speed up hot reloads
                        }
                    }
                ]
            },
            {
                test: /\.(png|svg|jpg|gif)$/,
                use: [
                    'file-loader'
                ]
            },
            {
                test: /\.(woff|woff2|eot|ttf|otf)$/,
                use: [
                    'file-loader'
                ]
            },
            {
                // opal-webpack-loader will compile and include ruby files in the pack
                test: /\.(rb|js.rb)$/,
                use: [
                    'opal-webpack-loader'
                ]
            }
        ]
    },
    // configuration for webpack serve
    serve: {
        devMiddleware: {
            publicPath: '/packs/',
            headers: {
                'Access-Control-Allow-Origin': '*'
            },
            watchOptions: {

            }
        },
        hotClient: {
            host: 'localhost',
            port: 8081,
            allEntries: true,
            hmr: true
        },
        host: "localhost",
        port: 3035,
        logLevel: 'debug',
        content: path.resolve(__dirname, '../../public/packs'),
        clipboard: false,
        open: false,
        on: {
            "listening": function (server) {
                const socket = new WebSocket('ws://localhost:8081');
                const watchPath = path.resolve(__dirname, '../../app/views');
                const options = {};
                const watcher = chokidar.watch(watchPath, options);

                watcher.on('change', () => {
                    const data = {
                        type: 'broadcast',
                        data: {
                            type: 'window-reload',
                            data: {},
                        },
                    };

                    socket.send(stringify(data));
                });

                server.server.on('close', () => {
                    watcher.close();
                });
            }
        }
    }
};
CODE

# ----------------------------------- Create webpack config production.js

file 'config/webpack/production.js', <<-CODE
const path = require('path');
const OpalWebpackResolverPlugin = require('opal-webpack-resolver-plugin');
const CompressionPlugin = require("compression-webpack-plugin")
const  ManifestPlugin = require('webpack-manifest-plugin');

module.exports = {
    parallelism: 8,
    context: path.resolve(__dirname, '../..'),
    mode: "production",
    optimization: {
        minimize: true
    },
    performance: {
        maxAssetSize: 20000000,
        maxEntrypointSize: 20000000
    },
    entry: {
        app: './app/javascript/app.js'
    },
    plugins: [
        new CompressionPlugin({ test: /\.js/ }),
        new ManifestPlugin()
    ],
    output: {
        filename: '[name]-[chunkhash].js',
        path: path.resolve(__dirname, '../../public/packs'),
        publicPath: '/packs/'
    },
    resolve: {
        plugins: [
            new OpalWebpackResolverPlugin('resolve', 'resolved')
        ]
    },
    module: {
        rules: [
            {
                test: /\.scss$/,
                use: [
                    {
                        loader: "style-loader",
                        options: {
                            hmr: false
                        }
                    },
                    {
                        loader: "css-loader"
                    },
                    {
                        loader: "sass-loader",
                        options: {
                            includePath: [
                                path.resolve(__dirname, '../../app/assets/stylesheets')
                            ]
                        }
                    }
                ]
            },
            {

                test: /\.css$/,
                use: [
                    'style-loader',
                    'css-loader'
                ]
            },
            {
                test: /\.(png|svg|jpg|gif)$/,
                use: [
                    'file-loader'
                ]
            },
            {
                test: /\.(woff|woff2|eot|ttf|otf)$/,
                use: [
                    'file-loader'
                ]
            },
            {
                test: /\.(rb|js.rb)$/,
                use: [
                    'opal-webpack-loader'
                ]
            }
        ]
    }
};
CODE

# ----------------------------------- Scripts for package.json

inject_into_file 'package.json', after: %r{"dependencies": {}} do
<<-CODE
,"scripts": {
  "test": "bundle exec opal-webpack-compile-server kill; bundle exec opal-webpack-compile-server && webpack --config=config/webpack/test.js; bundle exec opal-webpack-compile-server kill",
  "watch": "bundle exec opal-webpack-compile-server kill; bundle exec opal-webpack-compile-server && webpack --watch --config=config/webpack/development.js; bundle exec opal-webpack-compile-server kill",
  "start": "bundle exec opal-webpack-compile-server kill; bundle exec opal-webpack-compile-server && bundle exec webpack-serve --config ./config/webpack/development.js; bundle exec opal-webpack-compile-server kill",
  "build": "bundle exec opal-webpack-compile-server kill; bundle exec opal-webpack-compile-server && webpack --config=config/webpack/production.js; bundle exec opal-webpack-compile-server kill"
}
CODE
end

# ----------------------------------- Add NPM modules

run 'yarn add react'
run 'yarn add react-dom'
run 'yarn add react-router'
run 'yarn add opal-webpack-loader'
run 'yarn add opal-webpack-resolver-plugin'
run 'yarn add webpack-serve'

## ----------------------------------- Add to application_helper

inject_into_file 'app/helpers/application_helper.rb', after: 'module ApplicationHelper' do
<<-CODE

include Hyperstack::ViewHelpers

def owl_include_tag(path)
    case Rails.env
    when 'production'
      public, packs, asset = path.split('/')
      path = OpalWebpackManifest.lookup_path_for(asset)
      javascript_include_tag(path)
    when 'development' then javascript_include_tag('http://localhost:3035' + path[0..-4] + '_development' + path[-3..-1])
    when 'test' then javascript_include_tag(path[0..-4] + '_test' + path[-3..-1])
    end
  end
CODE
end

# ----------------------------------- View template

inject_into_file 'app/views/layouts/application.html.erb', after: %r{<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>} do
<<-CODE

<%= owl_include_tag '/packs/hyperstack.js' %>
CODE
end

# ----------------------------------- Procfile

file 'Procfile', <<-CODE
web:         bundle exec puma
webpack_dev: yarn run start
CODE

# ----------------------------------- Assets.rb

append_to_file 'config/initializers/assets.rb', <<-CODE

class OpalWebpackManifest
  def self.manifest
    @manifest ||= JSON.parse(File.read(File.join(Rails.root, 'public', 'packs', 'manifest.json')))
  end

  def self.lookup_path_for(asset)
    manifest[asset]
  end
end
CODE

# ----------------------------------- Commit Hyperstack setup

after_bundle do
  git add:    "."
  git commit: "-m 'Hyperstack config complete'"
end
