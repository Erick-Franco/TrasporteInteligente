// ════════════════════════════════════════════════════════
// 🛠️ ADMINISTRAR ASIGNACIONES - PANEL GERENTE (FIREBASE)
// panel-gerente/js/assignments.js
// ════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', async () => {
  // Verificar sesión
  auth.onAuthStateChanged(async (user) => {
    if (user) {
      // Cargar filtros
      await loadRutasFilter();
      // Cargar listado
      await loadAssignments();
    } else {
      window.location.href = 'index.html';
    }
  });

  document.getElementById('btn-filter').addEventListener('click', loadAssignments);
  document.getElementById('btn-clear').addEventListener('click', async () => {
    document.getElementById('filter-ruta').value = '';
    document.getElementById('filter-search').value = '';
    await loadAssignments();
  });

  document.getElementById('btn-back').addEventListener('click', () => {
    window.location.href = 'dashboard.html';
  });
  // Edit route button
  const btnEditRuta = document.getElementById('btn-edit-ruta');
  if (btnEditRuta) {
    btnEditRuta.addEventListener('click', openEditRouteModal);
  }
});

// ════════════════════════════════════════════════════════
// 🔍 CARGAR FILTROS
// ════════════════════════════════════════════════════════

async function loadRutasFilter() {
  try {
    const snapshot = await db.collection('rutas').get();
    const rutas = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const sel = document.getElementById('filter-ruta');

    // Verificar si el gerente tiene una ruta asignada (Opcional: preseleccionar pero no bloquear)
    const gerenteStorage = localStorage.getItem(CONFIG.STORAGE.GERENTE);
    let gerenteRutaId = null;

    if (gerenteStorage) {
      try {
        const gerenteData = JSON.parse(gerenteStorage);
        gerenteRutaId = gerenteData.ruta_id;
      } catch (e) {
        console.error('Error parsing gerente storage', e);
      }
    }

    sel.innerHTML = '<option value="">Todas las rutas</option>' +
      rutas.map(r => `<option value="${r.id}">${r.codigo || r.id} - ${r.nombre}</option>`).join('');

    // Si tiene ruta, preseleccionar pero NO bloquear
    if (gerenteRutaId) {
      const exists = rutas.find(r => r.id === gerenteRutaId);
      if (exists) {
        sel.value = gerenteRutaId;
      }
    }

    sel.disabled = false; // Siempre habilitado para editar otras rutas

  } catch (e) {
    console.error('Error cargando rutas:', e);
  }
}

// ════════════════════════════════════════════════════════
// 🗺️ EDITAR RUTA (modal)
// ════════════════════════════════════════════════════════
async function openEditRouteModal() {
  const sel = document.getElementById('filter-ruta');
  const rutaId = sel ? sel.value : null;
  if (!rutaId) {
    alert('Selecciona primero una ruta en el filtro para editarla.');
    return;
  }

  try {
    const doc = await db.collection('rutas').doc(rutaId).get();
    if (!doc.exists) {
      alert('Ruta no encontrada');
      return;
    }
    const data = doc.data();
    document.getElementById('edit-route-id').value = doc.id;
    document.getElementById('edit-route-name').value = data.nombre || '';
    document.getElementById('edit-route-code').value = data.codigo || '';
    document.getElementById('edit-route-color').value = data.color || '#3B82F6';
    document.getElementById('edit-route-desc').value = data.descripcion || '';

    document.getElementById('edit-route-modal').style.display = 'block';
  } catch (e) {
    console.error('Error cargando ruta:', e);
    alert('Error al cargar ruta: ' + e.message);
  }
}

document.getElementById('btn-edit-route-cancel').addEventListener('click', () => {
  document.getElementById('edit-route-modal').style.display = 'none';
});

document.getElementById('btn-edit-route-save').addEventListener('click', async () => {
  const id = document.getElementById('edit-route-id').value;
  const nombre = document.getElementById('edit-route-name').value.trim();
  const codigo = document.getElementById('edit-route-code').value.trim();
  const color = document.getElementById('edit-route-color').value;
  const descripcion = document.getElementById('edit-route-desc').value.trim();

  if (!id) return alert('ID de ruta inválido');

  try {
    await db.collection('rutas').doc(id).update({
      nombre: nombre || null,
      codigo: codigo || null,
      color: color || null,
      descripcion: descripcion || null
    });

    document.getElementById('edit-route-modal').style.display = 'none';
    await loadRutasFilter();
    await loadAssignments();
    alert('Ruta actualizada');
  } catch (e) {
    console.error('Error guardando ruta:', e);
    alert('Error al guardar ruta: ' + e.message);
  }
});

// ════════════════════════════════════════════════════════
// 📋 CARGAR ASIGNACIONES
// ════════════════════════════════════════════════════════

async function loadAssignments() {
  const rutaId = document.getElementById('filter-ruta').value;
  const q = document.getElementById('filter-search').value.trim().toLowerCase();
  const container = document.getElementById('assignments-container');

  // Mostrar loading en la tabla
  container.innerHTML = `
    <tr>
      <td colspan="6" class="loading">
        <div class="spinner"></div> Cargando conductores...
      </td>
    </tr>
  `;

  try {
    // Obtener todos los conductores
    const snapshot = await db.collection('conductores').get();
    let conductores = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Filtrar en memoria (cliente)
    if (rutaId) {
      conductores = conductores.filter(c => c.ruta_id === rutaId);
    }

    if (q) {
      conductores = conductores.filter(c =>
        (c.nombre && c.nombre.toLowerCase().includes(q)) ||
        (c.licencia && c.licencia.toLowerCase().includes(q)) ||
        (c.placa && c.placa.toLowerCase().includes(q))
      );
    }

    renderAssignments(conductores);

  } catch (e) {
    console.error('Error en loadAssignments', e);
    container.innerHTML = `
      <tr>
        <td colspan="6" class="empty-state" style="color: var(--danger)">
          Error cargando datos: ${e.message}
        </td>
      </tr>
    `;
  }
}

// ════════════════════════════════════════════════════════
// 🎨 RENDERIZADO (TABLA)
// ════════════════════════════════════════════════════════

function renderAssignments(conductores) {
  const container = document.getElementById('assignments-container');

  if (!conductores || conductores.length === 0) {
    container.innerHTML = `
      <tr>
        <td colspan="6" class="empty-state">
          No se encontraron conductores con los filtros actuales.
        </td>
      </tr>
    `;
    return;
  }

  container.innerHTML = conductores.map(c => `
    <tr>
      <td>
        <div style="font-weight: 600;">${c.nombre || 'Sin Nombre'}</div>
        <div style="font-size: 12px; color: var(--text-gray);">${c.email || ''}</div>
      </td>
      <td>${c.licencia || '---'}</td>
      <td>
        <div>${c.placa || '---'}</div>
        <div style="font-size: 12px; color: var(--text-gray);">${c.modelo_vehiculo || ''}</div>
      </td>
      <td>
        ${c.ruta_nombre ? `<strong>${c.ruta_nombre}</strong>` : (c.ruta_id || '<span style="color: var(--text-gray)">Sin Asignar</span>')}
      </td>
      <td>
        <span class="badge ${c.disponible ? 'badge-success' : 'badge-danger'}">
          ${c.disponible ? 'Activo' : 'Inactivo'}
        </span>
      </td>
      <td>
        <button class="btn-edit" data-id="${c.id}" title="Editar Conductor">
          <i class="fas fa-edit"></i> Editar
        </button>
      </td>
    </tr>
  `).join('');

  // Event Listeners
  container.querySelectorAll('.btn-edit').forEach(b => b.addEventListener('click', (e) => {
    const id = e.currentTarget.dataset.id;
    openEditModal(id);
  }));
}

// ════════════════════════════════════════════════════════
// 🛠️ Edición / Asignación directa (modal)
// ════════════════════════════════════════════════════════
async function openEditModal(conductorId) {
  try {
    // Cargar conductor desde Firestore
    const doc = await db.collection('conductores').doc(conductorId).get();
    if (!doc.exists) {
      alert('Conductor no encontrado');
      return;
    }

    const data = { id: doc.id, ...doc.data() };
    document.getElementById('edit-conductor-id').value = data.id;

    // Cargar selects
    await loadRutasForEdit();
    await loadVehiculosForEdit();

    // Preseleccionar
    if (data.ruta_id) document.getElementById('edit-ruta').value = data.ruta_id;
    if (data.vehiculo_id) document.getElementById('edit-vehiculo').value = data.vehiculo_id;

    // Preseleccionar estado
    const estadoSelect = document.getElementById('edit-estado');
    if (estadoSelect) {
      estadoSelect.value = (data.disponible === true) ? "true" : "false";
    }

    // Mostrar modal
    document.getElementById('edit-modal').style.display = 'block';
  } catch (e) {
    console.error('Error abriendo modal:', e);
    alert('Error al abrir la edición: ' + e.message);
  }
}

document.getElementById('btn-edit-cancel').addEventListener('click', () => {
  document.getElementById('edit-modal').style.display = 'none';
});

document.getElementById('btn-edit-save').addEventListener('click', async () => {
  const conductorId = document.getElementById('edit-conductor-id').value;
  const rutaId = document.getElementById('edit-ruta').value || null;
  const vehiculoId = document.getElementById('edit-vehiculo').value || null;
  const estadoVal = document.getElementById('edit-estado').value;
  const isDisponible = (estadoVal === 'true');

  try {
    // Obtener nombres/placa para guardarlos en conductor (mejor UX)
    let rutaNombre = null;
    let vehiculoInfo = {};

    if (rutaId) {
      const rdoc = await db.collection('rutas').doc(rutaId).get();
      if (rdoc.exists) rutaNombre = rdoc.data().nombre || null;
    }

    if (vehiculoId) {
      const vdoc = await db.collection('vehiculos').doc(vehiculoId).get();
      if (vdoc.exists) vehiculoInfo = vdoc.data();
    }

    // Actualizar documento del conductor
    const update = {};
    if (rutaId) update.ruta_id = rutaId;
    if (rutaNombre) update.ruta_nombre = rutaNombre;
    if (vehiculoId) update.vehiculo_id = vehiculoId;
    if (vehiculoInfo.placa) update.placa = vehiculoInfo.placa;
    if (vehiculoInfo.placa) update.placa = vehiculoInfo.placa;
    if (vehiculoInfo.modelo) update.modelo_vehiculo = vehiculoInfo.modelo;

    // Actualizar estado
    update.disponible = isDisponible;

    await db.collection('conductores').doc(conductorId).update(update);

    // Opcional: actualizar coleccion vehiculos para marcar conductor asignado
    if (vehiculoId) {
      await db.collection('vehiculos').doc(vehiculoId).update({ conductor_id: conductorId });
    }

    document.getElementById('edit-modal').style.display = 'none';
    await loadAssignments();
    alert('Asignación guardada correctamente');
  } catch (e) {
    console.error('Error guardando asignación:', e);
    alert('Error al guardar: ' + e.message);
  }
});

async function loadRutasForEdit() {
  const sel = document.getElementById('edit-ruta');
  if (!sel) return;
  try {
    const snapshot = await db.collection('rutas').get();
    const rutas = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    sel.innerHTML = '<option value="">-- Sin cambio --</option>' + rutas.map(r => `<option value="${r.id}">${r.codigo || r.id} - ${r.nombre}</option>`).join('');
  } catch (e) { console.error('Error cargando rutas:', e); }
}

async function loadVehiculosForEdit() {
  const sel = document.getElementById('edit-vehiculo');
  if (!sel) return;
  try {
    const snapshot = await db.collection('vehiculos').get();
    const vehiculos = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    sel.innerHTML = '<option value="">-- Sin cambio --</option>' + vehiculos.map(v => `<option value="${v.id}">${v.placa} - ${v.modelo || ''}</option>`).join('');
  } catch (e) { console.error('Error cargando vehiculos:', e); }
}
