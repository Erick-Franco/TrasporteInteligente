// ════════════════════════════════════════════════════════
// 🗺️ MAPA Y TIEMPO REAL - PANEL GERENTE (FIREBASE)
// panel-gerente/js/map.js
// ════════════════════════════════════════════════════════

let map;
let gerenteData;
let conductoresActivos = new Map();
let busMarkers = new Map();
let rutaPolyline;
let paraderoMarkers = [];
let unsubscribeConductores = null;
let unsubscribeUbicaciones = null;

// ════════════════════════════════════════════════════════
// 🚀 INICIALIZACIÓN
// ════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', async () => {
  setupEventListeners();

  auth.onAuthStateChanged(async (user) => {
    if (user) {
      console.log('✅ Usuario autenticado:', user.email);

      try {
        await loadGerenteInfo(user.uid);
        initMap();

        if (gerenteData && gerenteData.ruta_id) {
          await showRutaOnMap(gerenteData.ruta_id);
          listenToConductores();
          listenToUbicaciones();
        } else {
          console.warn('⚠️ Gerente no tiene ruta asignada');
          document.getElementById('conductores-container').innerHTML = `
            <div class="empty-state">
              <p>⚠️ No tienes una ruta asignada</p>
            </div>
          `;
        }
      } catch (error) {
        console.error('❌ Error crítico inicializando dashboard:', error);
        alert('Error cargando datos: ' + error.message);
      }
    } else {
      window.location.href = 'index.html';
    }
  });
});

async function loadGerenteInfo(uid) {
  try {
    console.log('🔍 Cargando datos del gerente desde Firestore...');
    console.log('   UID:', uid);

    const doc = await db.collection('gerentes').doc(uid).get();

    if (doc.exists) {
      gerenteData = { uid: uid, ...doc.data() };
      console.log('👤 Datos de gerente cargados desde Firestore:', gerenteData);
      localStorage.setItem(CONFIG.STORAGE.GERENTE, JSON.stringify(gerenteData));
    } else {
      console.warn('⚠️ No se encontró perfil de gerente en Firestore');
      gerenteData = {
        uid: uid,
        nombre: auth.currentUser.displayName || 'Gerente',
        email: auth.currentUser.email,
        ruta_id: 'ruta_18',
        ruta_nombre: 'Línea 18',
        ruta_codigo: 'L-18'
      };
    }

    document.getElementById('gerente-nombre').textContent = gerenteData.nombre || 'Gerente';
    document.getElementById('gerente-email').textContent = gerenteData.email;
    document.getElementById('gerente-telefono').textContent = gerenteData.telefono || '---';
    document.getElementById('ruta-nombre').textContent = gerenteData.ruta_nombre || (gerenteData.ruta_id ? 'Ruta ' + gerenteData.ruta_id : 'Sin Ruta');
    document.getElementById('ruta-codigo').textContent = gerenteData.ruta_codigo || '---';
  } catch (error) {
    console.error('❌ Error cargando datos gerente:', error);
    throw error;
  }
}

function initMap() {
  map = L.map('map').setView(CONFIG.MAP.DEFAULT_CENTER, CONFIG.MAP.DEFAULT_ZOOM);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: CONFIG.MAP.MAX_ZOOM,
    minZoom: CONFIG.MAP.MIN_ZOOM
  }).addTo(map);
  console.log('✅ Mapa inicializado');
}

async function showRutaOnMap(rutaId) {
  try {
    console.log(`🔍 Cargando ruta ${rutaId} desde Firestore...`);
    const rutaDoc = await db.collection('rutas').doc(rutaId).get();
    if (!rutaDoc.exists) {
      console.error('❌ Ruta no encontrada');
      return;
    }

    const puntosSnapshot = await db.collection('rutas')
      .doc(rutaId)
      .collection('puntos_control')
      .orderBy('orden')
      .get();

    const puntos = puntosSnapshot.docs.map(doc => doc.data());

    if (puntos.length > 0) {
      const puntosIda = puntos.filter(p => p.tipo === 'ida');
      const coords = puntosIda.map(p => [p.latitud, p.longitud]);
      if (rutaPolyline) map.removeLayer(rutaPolyline);
      rutaPolyline = L.polyline(coords, {
        color: '#3B82F6',
        weight: 4,
        opacity: 0.7
      }).addTo(map);
      map.fitBounds(rutaPolyline.getBounds(), { padding: [50, 50] });
    }

    const paraderos = puntos.filter(p => p.es_paradero === true);
    paraderoMarkers.forEach(m => map.removeLayer(m));
    paraderoMarkers = [];
    paraderos.forEach(p => {
      const marker = L.circleMarker([p.latitud, p.longitud], {
        radius: 6,
        fillColor: '#EF4444',
        color: '#fff',
        weight: 2,
        opacity: 1,
        fillOpacity: 0.8
      }).bindPopup(`<b>🚏 ${p.nombre || 'Paradero'}</b>`).addTo(map);
      paraderoMarkers.push(marker);
    });

    console.log(`✅ Ruta dibujada: ${puntos.length} puntos`);
  } catch (error) {
    console.error('❌ Error mostrando ruta:', error);
  }
}

function listenToConductores() {
  console.log('🎧 Escuchando cambios en conductores...');
  console.log('🔍 Buscando conductores para ruta:', gerenteData.ruta_id);

  let query = db.collection('conductores').where('ruta_id', '==', gerenteData.ruta_id);

  unsubscribeConductores = query.onSnapshot((snapshot) => {
    const conductoresList = [];
    console.log(`📦 Snapshot conductores recibido: ${snapshot.size} documentos encontrados`);

    snapshot.forEach(doc => {
      const conductor = doc.data();
      conductor.id = doc.id;
      conductoresList.push(conductor);
      console.log('👤 Conductor encontrado:', conductor.nombre, '- Placa:', conductor.placa);

      if (!conductoresActivos.has(conductor.id)) {
        conductoresActivos.set(conductor.id, conductor);
      } else {
        const current = conductoresActivos.get(conductor.id);
        conductoresActivos.set(conductor.id, { ...current, ...conductor });
      }
    });

    console.log('🎨 Renderizando lista con', conductoresList.length, 'conductores');
    renderConductoresList(conductoresList);
    updateStats();
  }, (error) => {
    console.error('❌ Error escuchando conductores:', error);
    const container = document.getElementById('conductores-container');
    if (container) {
      container.innerHTML = `
        <div class="empty-state" style="color: #EF4444;">
          <p>❌ Error cargando conductores</p>
          <p style="font-size: 12px;">${error.message}</p>
        </div>
      `;
    }
  });
}

function listenToUbicaciones() {
  console.log('🛰️ Escuchando ubicaciones GPS...');
  const ubicacionesRef = rtdb.ref('ubicaciones_tiempo_real');

  unsubscribeUbicaciones = ubicacionesRef.on('value', (snapshot) => {
    const data = snapshot.val();
    if (!data) return;

    Object.keys(data).forEach(conductorId => {
      const locationData = data[conductorId];
      const conductor = conductoresActivos.get(conductorId);

      if (conductor) {
        conductor.latitud = locationData.latitud;
        conductor.longitud = locationData.longitud;
        conductor.velocidad = locationData.velocidad;
        conductor.ultima_actualizacion = new Date(locationData.timestamp);
        updateBusMarker(conductor);
        updateConductorCard(conductorId, conductor);
      }
    });
  });
}

function updateBusMarker(conductor) {
  if (!conductor.latitud || !conductor.longitud) return;
  const conductorId = conductor.id || conductor.conductor_id;

  const busIcon = L.divIcon({
    html: `
      <div style="
        background: ${getBusColor(conductor.velocidad)};
        width: 32px;
        height: 32px;
        border-radius: 50%;
        border: 3px solid white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.3);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 16px;
        transition: background 0.3s;
      ">
        🚌
      </div>
    `,
    className: 'bus-marker',
    iconSize: [32, 32],
    iconAnchor: [16, 16]
  });

  if (busMarkers.has(conductorId)) {
    const marker = busMarkers.get(conductorId);
    marker.setLatLng([conductor.latitud, conductor.longitud]);
    marker.setIcon(busIcon);
    if (marker.isPopupOpen()) {
      marker.setPopupContent(getPopupContent(conductor));
    }
  } else {
    const marker = L.marker([conductor.latitud, conductor.longitud], {
      icon: busIcon
    }).bindPopup(getPopupContent(conductor)).addTo(map);
    busMarkers.set(conductorId, marker);
  }
}

function getPopupContent(c) {
  return `
    <div class="bus-popup">
      <h4>🚌 ${c.placa || 'Sin Placa'}</h4>
      <p><strong>Conductor:</strong> ${c.nombre || 'Desconocido'}</p>
      <p><strong>Modelo:</strong> ${c.modelo_vehiculo || '---'}</p>
      <span class="speed">${Math.round(c.velocidad || 0)} km/h</span>
    </div>
  `;
}

function getBusColor(velocidad) {
  if (!velocidad || velocidad < 1) return CONFIG.BUS_COLORS.stopped;
  if (velocidad < 20) return CONFIG.BUS_COLORS.slow;
  return CONFIG.BUS_COLORS.moving;
}

function renderConductoresList(conductores) {
  const container = document.getElementById('conductores-container');

  if (conductores.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <p>😴 No hay conductores activos</p>
      </div>
    `;
    return;
  }

  container.innerHTML = conductores.map(c => `
    <div class="conductor-card" id="card-${c.id}" onclick="centerMapOn('${c.id}')">
      <div class="conductor-header">
        <div class="conductor-name">${c.nombre || 'Conductor'}</div>
        <div class="conductor-status">
          <span class="status-dot" style="background: ${c.disponible ? '#10B981' : '#EF4444'}"></span>
          ${c.disponible ? 'Activo' : 'Inactivo'}
        </div>
      </div>
      <div class="conductor-details">
        <div>🚗 ${c.placa || '---'}</div>
        <div>⚡ <span id="speed-${c.id}">${Math.round(c.velocidad || 0)}</span> km/h</div>
      </div>
    </div>
  `).join('');
}

function updateConductorCard(id, data) {
  const speedEl = document.getElementById(`speed-${id}`);
  if (speedEl) {
    speedEl.textContent = Math.round(data.velocidad || 0);
  }
}

window.centerMapOn = function (id) {
  const conductor = conductoresActivos.get(id);
  if (conductor && conductor.latitud && conductor.longitud) {
    map.setView([conductor.latitud, conductor.longitud], 16);
    const marker = busMarkers.get(id);
    if (marker) marker.openPopup();
  }
};

function updateStats() {
  const total = conductoresActivos.size;
  let velocidadSum = 0;
  let count = 0;

  conductoresActivos.forEach(c => {
    if (c.velocidad) {
      velocidadSum += c.velocidad;
      count++;
    }
  });

  const promedio = count > 0 ? Math.round(velocidadSum / count) : 0;
  document.getElementById('stat-conductores').textContent = total;
  document.getElementById('stat-velocidad').textContent = promedio + ' km/h';
}

function setupEventListeners() {
  document.getElementById('btn-logout').addEventListener('click', () => {
    if (confirm('¿Cerrar sesión?')) {
      localStorage.removeItem(CONFIG.STORAGE.GERENTE);
      auth.signOut().then(() => {
        window.location.href = 'index.html';
      });
    }
  });

  document.getElementById('btn-center').addEventListener('click', () => {
    if (rutaPolyline) {
      map.fitBounds(rutaPolyline.getBounds(), { padding: [50, 50] });
    }
  });

  document.getElementById('btn-refresh').addEventListener('click', () => {
    window.location.reload();
  });
}