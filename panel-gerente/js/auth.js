// ════════════════════════════════════════════════════════
// 🔐 AUTENTICACIÓN - PANEL GERENTE
// panel-gerente/js/auth.js
// ════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
  const loginForm = document.getElementById('login-form');
  const btnLogin = document.getElementById('btn-login');
  const alertContainer = document.getElementById('alert-container');

  // Verificar si ya está logueado
  checkExistingSession();

  // Manejar submit del formulario
  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    await handleLogin();
  });

  /**
   * Manejar el login
   */
  async function handleLogin() {
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;

    // Validaciones básicas
    if (!email || !password) {
      showAlert('Por favor, completa todos los campos', 'error');
      return;
    }

    // Deshabilitar botón
    btnLogin.disabled = true;
    btnLogin.innerHTML = `
      <div class="spinner"></div>
      Iniciando sesión...
    `;

    try {
      const response = await fetch(`${CONFIG.API_URL}/gerente/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email, password })
      });

      const data = await response.json();

      if (response.ok && data.success) {
        // Guardar datos del gerente en localStorage
        localStorage.setItem(CONFIG.STORAGE.GERENTE, JSON.stringify(data.gerente));

        // Mostrar mensaje de éxito
        showAlert(CONFIG.MESSAGES.LOGIN_SUCCESS, 'success');

        // Redirigir al dashboard después de 1 segundo
        setTimeout(() => {
          window.location.href = 'dashboard.html';
        }, 1000);

      } else {
        showAlert(data.error || CONFIG.MESSAGES.LOGIN_ERROR, 'error');
        btnLogin.disabled = false;
        btnLogin.innerHTML = 'Iniciar Sesión';
      }

    } catch (error) {
      console.error('Error al hacer login:', error);
      showAlert(CONFIG.MESSAGES.CONNECTION_ERROR, 'error');
      btnLogin.disabled = false;
      btnLogin.innerHTML = 'Iniciar Sesión';
    }
  }

  /**
   * Verificar si hay una sesión activa
   */
  function checkExistingSession() {
    const gerenteData = localStorage.getItem(CONFIG.STORAGE.GERENTE);
    
    if (gerenteData) {
      // Si ya está logueado, redirigir al dashboard
      window.location.href = 'dashboard.html';
    }
  }

  /**
   * Mostrar alerta
   */
  function showAlert(message, type) {
    const alertClass = type === 'error' ? 'alert-error' : 'alert-success';
    
    alertContainer.innerHTML = `
      <div class="alert ${alertClass}">
        ${message}
      </div>
    `;

    // Auto-ocultar después de 5 segundos
    setTimeout(() => {
      alertContainer.innerHTML = '';
    }, 5000);
  }
});