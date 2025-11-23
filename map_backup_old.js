// ════════════════════════════════════════════════════════
// 🗺️ MAPA Y TIEMPO REAL - PANEL GERENTE
// panel-gerente/js/map.js
// ════════════════════════════════════════════════════════

let map;
let socket;
let gerenteData;
let conductoresActivos = new Map();
let busMarkers = new Map();
let rutaPolyline;
let paraderoMarkers = [];
let rutasList = [];

// ════════════════════════════════════════════════════════
// 🚀 INICIALIZACIÓN
// ════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', async () => {
  // Verificar sesión
  checkAuth();
  
  // Cargar datos del gerente
  loadGerenteInfo();
  
  // Inicializar mapa
  initMap();
  
  // Conectar WebSocket
  initWebSocket();
  
  // Cargar lista de rutas y mostrar la del gerente
  await loadAllRutas();
  await showRutaOnMap(gerenteData.ruta_id);
  
  // Cargar conductores/buses/viajes activos
  await loadConductoresActivos();
  await loadViajesActivos();
  
  // Cargar estadísticas
  await loadEstadisticas();
  
  // Event listeners
  setupEventListeners();
  
  // Auto-refresh cada 30 segundos
  setInterval(loadEstadisticas, 30000);

  // Refrescar viajes y ubicaciones en tiempo real según configuración
  setInterval(() => {
    loadViajesActivos();
    loadConductoresActivos();
  }, CONFIG.UPDATE_INTERVAL);
});

// ════════════════════════════════════════════════════════
// 🔐 AUTENTICACIÓN
// ════════════════════════════════════════════════════════

function checkAuth() {
  const data = localStorage.getItem(CONFIG.STORAGE.GERENTE);
  
  if (!data) {
    window.location.href = 'index.html';
    return;
  }
  
  gerenteData = JSON.parse(data);
  console.log('✅ Gerente autenticado:', gerenteData.nombre);
}

function loadGerenteInfo() {
  document.getElementById('gerente-nombre').textContent = gerenteData.nombre;
  document.getElementById('gerente-email').textContent = gerenteData.email;
  document.getElementById('gerente-telefono').textContent = gerenteData.telefono || 'N/A';
  document.getElementById('ruta-nombre').textContent = gerenteData.ruta_nombre;
  document.getElementById('ruta-codigo').textContent = gerenteData.ruta_codigo;
}

// ════════════════════════════════════════════════════════
// 🗺️ INICIALIZAR MAPA
// ════════════════════════════════════════════════════════

function initMap() {
  map = L.map('map').setView(CONFIG.MAP.DEFAULT_CENTER, CONFIG.MAP.DEFAULT_ZOOM);
  
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: CONFIG.MAP.MAX_ZOOM,
    minZoom: CONFIG.MAP.MIN_ZOOM
  }).addTo(map);
  
  console.log('✅ Mapa inicializado');
}

// ════════════════════════════════════════════════════════
// 🔌 WEBSOCKET
// ════════════════════════════════════════════════════════

function initWebSocket() {
  socket = io(CONFIG.WS_URL);
  
  socket.on('connect', () => {
    console.log('✅ WebSocket conectado');
    
    // Suscribirse a la ruta del gerente
    socket.emit('subscribe-route', {
      ruta_id: gerenteData.ruta_id
    });
    
    console.log(`📍 Suscrito a ruta ${gerenteData.ruta_id}`);
  });
  
  socket.on('disconnect', () => {
    console.log('❌ WebSocket desconectado');
  });
  
  // Escuchar actualizaciones de GPS
  socket.on('conductor-movimiento', (data) => {
    console.log('📍 Conductor movimiento:', data);
    updateBusMarker(data);
  });
  
  socket.on('bus-location-update', (data) => {
    console.log('📍 Bus location update:', data);
    if (data.ruta_id === gerenteData.ruta_id) {
      updateBusMarker(data);
    }
  });

  // Eventos de viajes
  socket.on('viaje-iniciado', (payload) => {
    console.log('📡 Evento viaje-iniciado', payload);
    // Recargar viajes activos y marcadores
    loadViajesActivos();
  });

  socket.on('viaje-finalizado', (payload) => {
    console.log('📡 Evento viaje-finalizado', payload);
    loadViajesActivos();
  });

  socket.on('bus-arrived-stop', (payload) => {
    console.log('📍 Bus arrived stop:', payload);
    // Podríamos mostrar notificación o actualizar UI
    loadViajesActivos();
  });
}

// ════════════════════════════════════════════════════════
// 📍 CARGAR RUTA COMPLETA
// ════════════════════════════════════════════════════════

async function loadRutaCompleta() {
  try {
    const url = `${CONFIG.API_URL}/gerente/${gerenteData.ruta_id}/ruta-completa?tipo=ida`;
    console.log('🔍 Cargando ruta desde:', url);
    
    const response = await fetch(url);
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const data = await response.json();
    console.log('📦 Respuesta ruta:', data);
    
    if (data.success && data.puntos_gps && data.puntos_gps.length > 0) {
      // Dibujar ruta en el mapa
      const rutaCoords = data.puntos_gps.map(p => [p.latitud, p.longitud]);
      
      rutaPolyline = L.polyline(rutaCoords, {
        color: gerenteData.ruta_color || '#3B82F6',
        weight: 4,
        opacity: 0.7
      }).addTo(map);
      
      // Agregar paraderos
      if (data.paraderos && data.paraderos.length > 0) {
        data.paraderos.forEach(paradero => {
          L.circleMarker([paradero.latitud, paradero.longitud], {
            radius: 6,
            fillColor: '#EF4444',
            color: '#fff',
            weight: 2,
            opacity: 1,
            fillOpacity: 0.8
          })
          .bindPopup(`
            <div class="bus-popup">
              <h4>🚏 ${paradero.nombre}</h4>
              ${paradero.descripcion ? `<p>${paradero.descripcion}</p>` : ''}
            </div>
          `)
          .addTo(map);
        });
      }
      
      // Centrar mapa en la ruta
      map.fitBounds(rutaPolyline.getBounds(), { padding: [50, 50] });
      
      console.log(`✅ Ruta dibujada: ${data.puntos_gps.length} puntos, ${data.paraderos.length} paraderos`);
    } else {
      console.warn('⚠️ No hay puntos GPS para esta ruta');
    }
    
  } catch (error) {
    console.error('❌ Error cargando ruta:', error);
  }
}

// ════════════════════════════════════════════════════════
// 🚌 CARGAR CONDUCTORES ACTIVOS
// ════════════════════════════════════════════════════════

async function loadConductoresActivos() {
  try {
    const url = `${CONFIG.API_URL}/gerente/${gerenteData.ruta_id}/conductores-activos`;
    console.log('🔍 Cargando conductores desde:', url);
    
    const response = await fetch(url);
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const data = await response.json();
    console.log('📦 Respuesta conductores:', data);
    
    if (data.success) {
      conductoresActivos.clear();
      
      data.conductores.forEach(conductor => {
        conductoresActivos.set(conductor.conductor_id, conductor);
        
        // Agregar marker si tiene ubicación
        if (conductor.latitud && conductor.longitud) {
          addBusMarker(conductor);
        }
      });
      
      renderConductoresList(data.conductores);
      updateStats();
      
      console.log(`✅ ${data.conductores.length} conductores activos cargados`);
    }
    
  } catch (error) {
    console.error('❌ Error cargando conductores:', error);
    document.getElementById('conductores-container').innerHTML = `
      <div class="empty-state">
        <p>❌ Error al cargar conductores</p>
        <p style="font-size: 12px; color: var(--gray);">${error.message}</p>
      </div>
    `;
  }
}

// ════════════════════════════════════════════════════════
// 🚌 MARKERS DE BUSES
// ════════════════════════════════════════════════════════

function addBusMarker(conductor) {
  const conductorId = conductor.conductor_id;
  
  console.log(`🚌 Agregando marker para conductor ${conductorId}:`, conductor.latitud, conductor.longitud);
  
  // Crear ícono del bus
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
      ">
        🚌
      </div>
    `,
    className: 'bus-marker',
    iconSize: [32, 32],
    iconAnchor: [16, 16]
  });
  
  // Crear marker
  const marker = L.marker([conductor.latitud, conductor.longitud], {
    icon: busIcon
  })
  .bindPopup(`
    <div class="bus-popup">
      <h4>🚌 ${conductor.placa}</h4>
      <p><strong>Conductor:</strong> ${conductor.conductor_nombre}</p>
      <p><strong>Modelo:</strong> ${conductor.modelo}</p>
      <p><strong>Licencia:</strong> ${conductor.licencia}</p>
      <span class="speed">${conductor.velocidad || 0} km/h</span>
    </div>
  `)
  .addTo(map);
  
  busMarkers.set(conductorId, marker);
}

function updateBusMarker(data) {
  const conductorId = data.conductor_id;
  
  console.log(`🔄 Actualizando marker conductor ${conductorId}:`, data.latitud, data.longitud);
  
  // Actualizar en el Map
  if (conductoresActivos.has(conductorId)) {
    const conductor = conductoresActivos.get(conductorId);
    conductor.latitud = data.latitud;
    conductor.longitud = data.longitud;
    conductor.velocidad = data.velocidad;
    conductor.ultima_actualizacion = new Date();
  }
  
  // Actualizar marker en el mapa
  if (busMarkers.has(conductorId)) {
    const marker = busMarkers.get(conductorId);
    marker.setLatLng([data.latitud, data.longitud]);
    
    // Actualizar color según velocidad
    const newIcon = L.divIcon({
      html: `
        <div style="
          background: ${getBusColor(data.velocidad)};
          width: 32px;
          height: 32px;
          border-radius: 50%;
          border: 3px solid white;
          box-shadow: 0 2px 4px rgba(0,0,0,0.3);
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 16px;
        ">
          🚌
        </div>
      `,
      className: 'bus-marker',
      iconSize: [32, 32],
      iconAnchor: [16, 16]
    });
    marker.setIcon(newIcon);
  } else {
    // Si no existe el marker, crearlo
    const conductor = conductoresActivos.get(conductorId);
    if (conductor) {
      conductor.latitud = data.latitud;
      conductor.longitud = data.longitud;
      conductor.velocidad = data.velocidad;
      addBusMarker(conductor);
    }
  }
  
  // Actualizar lista de conductores
  updateConductorCard(conductorId, data);
}

function getBusColor(velocidad) {
  if (!velocidad || velocidad === 0) return CONFIG.BUS_COLORS.stopped;
  if (velocidad < 10) return CONFIG.BUS_COLORS.slow;
  if (velocidad < 30) return CONFIG.BUS_COLORS.moving;
  return CONFIG.BUS_COLORS.default;
}

// ════════════════════════════════════════════════════════
// 📊 RENDERIZAR LISTA DE CONDUCTORES
// ════════════════════════════════════════════════════════

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
    <div class="conductor-card" data-conductor-id="${c.conductor_id}">
      <div class="conductor-header">
        <div class="conductor-name">${c.conductor_nombre}</div>
        <div class="conductor-status">
          <span class="status-dot"></span>
          Activo
        </div>
      </div>
      <div class="conductor-details">
        <div>🚗 ${c.placa} - ${c.modelo}</div>
        <div>🎫 ${c.licencia}</div>
        <div>⚡ <span id="speed-${c.conductor_id}">${c.velocidad || 0}</span> km/h</div>
        <div id="update-time-${c.conductor_id}">
          🕐 ${c.ultima_actualizacion ? formatTime(c.ultima_actualizacion) : 'Sin datos'}
        </div>
      </div>
    </div>
  `).join('');
  
  // Event listeners para centrar mapa
  document.querySelectorAll('.conductor-card').forEach(card => {
    card.addEventListener('click', () => {
      const conductorId = parseInt(card.dataset.conductorId);
      const conductor = conductoresActivos.get(conductorId);
      
      if (conductor && conductor.latitud && conductor.longitud) {
        map.setView([conductor.latitud, conductor.longitud], 16);
        
        if (busMarkers.has(conductorId)) {
          busMarkers.get(conductorId).openPopup();
        }
      }
    });
  });
}

function updateConductorCard(conductorId, data) {
  const timeElement = document.getElementById(`update-time-${conductorId}`);
  if (timeElement) {
    timeElement.textContent = `🕐 ${formatTime(new Date())}`;
  }
  
  const speedElement = document.getElementById(`speed-${conductorId}`);
  if (speedElement) {
    speedElement.textContent = data.velocidad || 0;
  }
}

// ════════════════════════════════════════════════════════
// 📊 ESTADÍSTICAS
// ════════════════════════════════════════════════════════

async function loadEstadisticas() {
  try {
    const url = `${CONFIG.API_URL}/gerente/${gerenteData.ruta_id}/estadisticas`;
    console.log('🔍 Cargando estadísticas desde:', url);
    
    const response = await fetch(url);
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const data = await response.json();
    console.log('📦 Respuesta estadísticas:', data);
    
    if (data.success) {
      document.getElementById('stat-conductores').textContent = 
        data.estadisticas.conductores_activos;
      document.getElementById('stat-velocidad').textContent = 
        data.estadisticas.velocidad_promedio + ' km/h';
      document.getElementById('stat-viajes').textContent = 
        data.estadisticas.viajes_completados_hoy;
      document.getElementById('stat-paraderos').textContent = 
        data.estadisticas.total_paraderos;
    }
    
  } catch (error) {
    console.error('❌ Error cargando estadísticas:', error);
  }
}

function updateStats() {
  document.getElementById('stat-conductores').textContent = conductoresActivos.size;
}

// ════════════════════════════════════════════════════════
// 🎮 EVENT LISTENERS
// ════════════════════════════════════════════════════════

function setupEventListeners() {
  // Botón de logout
  document.getElementById('btn-logout').addEventListener('click', () => {
    if (confirm('¿Seguro que deseas cerrar sesión?')) {
      localStorage.removeItem(CONFIG.STORAGE.GERENTE);
      socket.disconnect();
      window.location.href = 'index.html';
    }
  });
  
  // Botón de centrar mapa
  document.getElementById('btn-center').addEventListener('click', () => {
    if (rutaPolyline) {
      map.fitBounds(rutaPolyline.getBounds(), { padding: [50, 50] });
    }
  });
  
  // Botón de refrescar
  document.getElementById('btn-refresh').addEventListener('click', async () => {
    await loadConductoresActivos();
    await loadEstadisticas();
  });
}

// ════════════════════════════════════════════════════════
// 🛠️ UTILIDADES
// ════════════════════════════════════════════════════════

function formatTime(date) {
  const d = new Date(date);
  return d.toLocaleTimeString('es-PE', { 
    hour: '2-digit', 
    minute: '2-digit' 
  });
}

// ───────────────────────────────────────────────────────────
// 🗂️ CARGAR TODAS LAS RUTAS
// ───────────────────────────────────────────────────────────
async function loadAllRutas() {
  try {
    const url = `${CONFIG.API_URL}/rutas`;
    console.log('🔍 Cargando todas las rutas desde:', url);
    const response = await fetch(url);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const result = await response.json();
    if (result.success) {
      rutasList = result.data || [];
      renderRutasList(rutasList);
      console.log(`✅ ${rutasList.length} rutas cargadas`);
    }
  } catch (error) {
    console.error('❌ Error cargando rutas:', error);
    const el = document.getElementById('rutas-list');
    if (el) el.innerHTML = `<div class="empty-state">Error cargando rutas</div>`;
  }
}

function renderRutasList(rutas) {
  const container = document.getElementById('rutas-list');
  if (!container) return;
  if (!rutas || rutas.length === 0) {
    container.innerHTML = `<div class="empty-state">No hay rutas</div>`;
    return;
  }

  container.innerHTML = rutas.map(r => `
    <div class="ruta-item" data-ruta-id="${r.id}" style="border-left:4px solid ${r.color || '#3B82F6'}; padding-left:8px; margin-bottom:8px; cursor:pointer;">
      <div style="font-weight:600">${r.codigo} — ${r.nombre}</div>
      <div style="font-size:12px; color:var(--gray);">${r.descripcion || ''}</div>
    </div>
  `).join('');

  // click handlers
  document.querySelectorAll('.ruta-item').forEach(item => {
    item.addEventListener('click', () => {
      const id = item.dataset.rutaId;
      showRutaOnMap(parseInt(id));
    });
  });
}

// ───────────────────────────────────────────────────────────
// 🗺️ Mostrar ruta por ID (puntos + paraderos)
// ───────────────────────────────────────────────────────────
async function showRutaOnMap(rutaId, tipo = 'ida') {
  try {
    clearRutaFromMap();

    // Obtener puntos
    const puntosUrl = `${CONFIG.API_URL}/rutas/${rutaId}/puntos?tipo=${tipo}`;
    const paraderosUrl = `${CONFIG.API_URL}/rutas/${rutaId}/paraderos`;

    console.log('🔍 Cargando puntos de ruta:', puntosUrl);
    const [pResp, paResp] = await Promise.all([fetch(puntosUrl), fetch(paraderosUrl)]);
    if (!pResp.ok) throw new Error(`HTTP ${pResp.status} puntos`);
    if (!paResp.ok) throw new Error(`HTTP ${paResp.status} paraderos`);

    const pData = await pResp.json();
    const paData = await paResp.json();

    const puntos = (pData && pData.data) ? pData.data : [];
    const paraderos = (paData && paData.data) ? paData.data : [];

    if (puntos.length > 0) {
      const rutaCoords = puntos.map(p => [p.latitud, p.longitud]);
      rutaPolyline = L.polyline(rutaCoords, { color: '#3B82F6', weight: 4, opacity: 0.7 }).addTo(map);
      map.fitBounds(rutaPolyline.getBounds(), { padding: [50, 50] });
    }

    if (paraderos.length > 0) {
      paraderos.forEach(paradero => {
        const marker = L.circleMarker([paradero.latitud, paradero.longitud], {
          radius: 6,
          fillColor: '#EF4444',
          color: '#fff',
          weight: 2,
          opacity: 1,
          fillOpacity: 0.8
        })
        .bindPopup(`<div class="bus-popup"><h4>🚏 ${paradero.nombre}</h4>${paradero.descripcion ? `<p>${paradero.descripcion}</p>` : ''}</div>`) 
        .addTo(map);
        paraderoMarkers.push(marker);
      });
    }

    console.log(`✅ Ruta ${rutaId} mostrada: ${puntos.length} puntos, ${paraderos.length} paraderos`);
  } catch (error) {
    console.error('❌ Error mostrando ruta:', error);
  }
}

function clearRutaFromMap() {
  if (rutaPolyline) {
    map.removeLayer(rutaPolyline);
    rutaPolyline = null;
  }
  if (paraderoMarkers && paraderoMarkers.length > 0) {
    paraderoMarkers.forEach(m => map.removeLayer(m));
    paraderoMarkers = [];
  }
}

// ───────────────────────────────────────────────────────────
// 🚍 CARGAR VIAJES ACTIVOS (buses)
// ───────────────────────────────────────────────────────────
async function loadViajesActivos() {
  try {
    const url = `${CONFIG.API_URL}/viajes/activos`;
    console.log('🔍 Cargando viajes activos desde:', url);
    const response = await fetch(url);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    if (data.success) {
      // Normalizar y actualizar markers
      data.data.forEach(v => {
        const conductorId = v.conductor_id;
        const lat = v.ultima_latitud || v.latitud || null;
        const lng = v.ultima_longitud || v.longitud || null;
        const velocidad = v.velocidad || 0;

        if (!conductorId || !lat || !lng) return;

        const normalized = {
          conductor_id: conductorId,
          latitud: lat,
          longitud: lng,
          velocidad: velocidad,
          placa: v.vehiculo_placa || v.placa || '',
          conductor_nombre: v.conductor_nombre || ''
        };

        // Mantener en conductoresActivos para interacciones
        conductoresActivos.set(conductorId, normalized);

        // Actualizar/crear marker
        updateBusMarker({ conductor_id: conductorId, latitud: lat, longitud: lng, velocidad });
      });

      updateStats();
      console.log(`✅ ${data.data.length} viajes activos cargados`);
    }
  } catch (error) {
    console.error('❌ Error cargando viajes activos:', error);
  }
}