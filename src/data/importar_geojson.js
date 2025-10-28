import fs from "fs";
import path from "path";
import pkg from "pg";
const { Pool } = pkg;

// Load environment and configure DB connection
import dotenv from "dotenv";
dotenv.config();

const DRY_RUN = process.env.DRY_RUN === "true";

// Resolve data directory: allow override with GEOJSON_DIR, otherwise try common locations
const resolveDataDir = () => {
  if (process.env.GEOJSON_DIR) {
    const envPath = process.env.GEOJSON_DIR;
    return path.isAbsolute(envPath) ? envPath : path.join(process.cwd(), envPath);
  }

  const candidates = [
    path.join(process.cwd(), "data"),
    path.join(process.cwd(), "src", "scripts"),
    path.join(process.cwd(), "src", "data"),
    path.join(process.cwd(), "scripts")
  ];

  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }

  // fallback to a default path (may not exist)
  return candidates[0];
};

const dataDir = resolveDataDir();
console.log(`📁 Usando dataDir: ${dataDir}`);

let pool;
if (!DRY_RUN) {
  const connectionString = process.env.DATABASE_URL || process.env.PG_CONNECTION || process.env.SUPABASE_DB_URL;
  if (!connectionString) {
    console.error('No se encontró la cadena de conexión a la BD. Define DATABASE_URL (o PG_CONNECTION / SUPABASE_DB_URL) en .env');
    process.exit(1);
  }
  pool = new Pool({ connectionString });
} else {
  console.log('⚠️ Modo DRY_RUN activado — no se realizarán inserts en la base de datos.');
}

async function importarGeoJSON() {
  if (!fs.existsSync(dataDir)) {
    throw new Error(`Directorio de datos no existe: ${dataDir}`);
  }

  const files = fs.readdirSync(dataDir).filter(f => f.endsWith(".geojson"));
  console.log(`📂 Archivos encontrados: ${files.length}`);

  for (const file of files) {
    const rutaNombre = file.replace(".geojson", "");
    console.log(`🚍 Procesando ${rutaNombre}...`);

    const contenido = JSON.parse(fs.readFileSync(path.join(dataDir, file), "utf8"));

    if (DRY_RUN) {
      console.log(`(DRY) Insertar ruta: ${rutaNombre}`);
      // show counts that would be inserted
      let coordCount = 0;
      for (const feature of contenido.features || []) {
        const coords = feature.geometry && feature.geometry.coordinates ? feature.geometry.coordinates : [];
        const flattened = Array.isArray(coords[0]) && Array.isArray(coords[0][0]) ? coords.flat(1) : coords;
        coordCount += flattened.length;
      }
      console.log(`(DRY) Coordenadas que se insertarían: ${coordCount}`);
    } else {
      const insertRuta = await pool.query(
        "INSERT INTO rutas (nombre, descripcion, color, distancia_total, tiempo_promedio, precio_pasaje) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id",
        [rutaNombre, `${rutaNombre} - Importada automáticamente`, "#009688", 0, 0, 0]
      );

      const rutaId = insertRuta.rows[0].id;
      let orden = 1;

      for (const feature of contenido.features) {
        const coords = feature.geometry && feature.geometry.coordinates ? feature.geometry.coordinates : [];
        const flattened = Array.isArray(coords[0]) && Array.isArray(coords[0][0]) ? coords.flat(1) : coords;

        for (const point of flattened) {
          const [lon, lat] = point;
          await pool.query(
            "INSERT INTO coordenadas_ruta (ruta_id, orden, latitud, longitud) VALUES ($1, $2, $3, $4)",
            [rutaId, orden, lat, lon]
          );
          orden++;
        }
      }

      console.log(`✅ Ruta ${rutaNombre} importada con ID ${rutaId}`);
    }
  }

  if (pool) await pool.end();
  console.log("🎉 Importación completa.");
}

importarGeoJSON().catch(err => {
  console.error(err);
  if (pool) pool.end().catch(()=>{}).finally(()=>process.exit(1));
  else process.exit(1);
});
