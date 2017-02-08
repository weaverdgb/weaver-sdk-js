'use strict';

Object.defineProperty(exports, "__esModule",
  value: true
);

exports.default =  (filename, data, options)->
  return new Promise( (resolve, reject)->
    _fs2.default.writeFile(filename, data, options,  (err)->
      if err == null
        return resolve(filename)
      else return reject(err);
    )
  );


_fs = require('fs');

_interopRequireDefault = (obj)->
  obj && obj.__esModule ? obj : { default: obj };

_fs2 = _interopRequireDefault(_fs);


module.exports = exports['default'];
