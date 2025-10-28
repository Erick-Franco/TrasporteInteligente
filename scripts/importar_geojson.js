const path = require('path');
const { pathToFileURL } = require('url');

(async () => {
  try {
    const target = path.join(__dirname, '..', 'src', 'data', 'importar_geojson.js');
    await import(pathToFileURL(target).href);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
})();
