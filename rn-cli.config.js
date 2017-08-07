const path = require('path');

// Don't forget to everything listed here to `package.json`
// modulePathIgnorePatterns.
const sharedBlacklist = [
  /node_modules[/\\]react[/\\]dist[/\\].*/,

  'downstream/core/invariant.js',

  /docs\/.*/,
];

const platformBlacklists = {
  macos: ['.ios.js', '.android.js', /e2e\/.*/],
};

function escapeRegExp(pattern) {
  if (Object.prototype.toString.call(pattern) === '[object RegExp]') {
    return pattern.source.replace(/\//g, path.sep);
  } else if (typeof pattern === 'string') {
    const escaped = pattern.replace(
      /[\-\[\]\{\}\(\)\*\+\?\.\\\^\$\|]/g,
      '\\$&'
    );
    // convert the '/' into an escaped local file separator
    return escaped.replace(/\//g, `\\${path.sep}`);
  }
  throw new Error(`Unexpected packager blacklist pattern: ${pattern}`);
}

function blacklist(platform, additionalBlacklist) {
  // eslint-disable-next-line
  return new RegExp(
    '(' +
      (additionalBlacklist || [])
        .concat(sharedBlacklist)
        .concat(platformBlacklists[platform] || [])
        .map(escapeRegExp)
        .join('|') +
      ')$'
  );
}

module.exports = {
  getBlacklistRE(platform) {
    if (
      process &&
      process.argv.filter(a => a.indexOf('react-native-macos') > -1).length > 0
    ) {
      return blacklist('macos');
    }
    return blacklist(platform);
  },
};
