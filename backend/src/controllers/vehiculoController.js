// ============================================
// CONTROLADOR DE VEHÍCULOS
// backend/src/controllers/vehiculoController.js
// ============================================

const { query } = require('../config/database');

// Obtener todos los vehículos
const getAllVehiculos = async (req, res) => {
    try {
        const result = await query(`
            SELECT id, placa, modelo, capacidad, conductor_id, estado
            FROM vehiculos
            ORDER BY placa
        `);

        res.json({ success: true, data: result.rows, total: result.rowCount });
    } catch (error) {
        console.error('Error en getAllVehiculos:', error);
        res.status(500).json({ success: false, error: 'Error al obtener vehículos', message: error.message });
    }
};

module.exports = {
    getAllVehiculos
};
