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
  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      await handleLogin();
    });
  }

  /**
   * Manejar el login con Firebase
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
    if (btnLogin) {
      btnLogin.disabled = true;
      btnLogin.innerHTML = `
        <div class="spinner"></div>
        Iniciando sesión...
      `;
    }

    try {
      // Login con Firebase Auth
      const userCredential = await auth.signInWithEmailAndPassword(email, password);
      const user = userCredential.user;

      console.log('✅ Login exitoso:', user.email);

      // Obtener datos del gerente desde Firestore
      let gerenteData = {
        uid: user.uid,
        email: user.email,
        ruta_id: null // Por defecto null (ve todo)
      };

      try {
        const doc = await db.collection('gerentes').doc(user.uid).get();
        if (doc.exists) {
          const data = doc.data();
          gerenteData = { ...gerenteData, ...data };
          console.log('👤 Perfil de gerente cargado:', gerenteData);
        } else {
          console.warn('⚠️ No se encontró perfil de gerente en Firestore, usando datos básicos.');
        }
      } catch (err) {
        console.error('❌ Error cargando perfil de gerente:', err);
      }

      // Guardar datos en localStorage
      localStorage.setItem(CONFIG.STORAGE.GERENTE, JSON.stringify(gerenteData));

      // Mostrar mensaje de éxito
      showAlert(CONFIG.MESSAGES.LOGIN_SUCCESS, 'success');

      // Redirigir al dashboard
      setTimeout(() => {
        window.location.href = 'dashboard.html';
      }, 1000);

    } catch (error) {
      console.error('❌ Error al hacer login:', error);

      let errorMessage = CONFIG.MESSAGES.LOGIN_ERROR;

      // Mensajes de error específicos de Firebase
      if (error.code === 'auth/user-not-found' || error.code === 'auth/wrong-password') {
        errorMessage = 'Email o contraseña incorrectos';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = 'El formato del email no es válido';
      } else if (error.code === 'auth/too-many-requests') {
        errorMessage = 'Demasiados intentos fallidos. Intenta más tarde.';
      }

      showAlert(errorMessage, 'error');

      if (btnLogin) {
        btnLogin.disabled = false;
        btnLogin.innerHTML = 'Iniciar Sesión';
      }
    }
  }

  /**
   * Verificar si hay una sesión activa
   */
  function checkExistingSession() {
    // Verificar con Firebase Auth
    auth.onAuthStateChanged((user) => {
      if (user) {
        // Si estamos en index.html (login), redirigir al dashboard
        if (window.location.pathname.endsWith('index.html') || window.location.pathname.endsWith('/')) {
          console.log('🔄 Sesión activa, redirigiendo al dashboard...');
          window.location.href = 'dashboard.html';
        }
      } else {
        // Si NO estamos en index.html, redirigir al login
        if (!window.location.pathname.endsWith('index.html') && !window.location.pathname.endsWith('/')) {
          console.log('🔒 No hay sesión, redirigiendo al login...');
          window.location.href = 'index.html';
        }
      }
    });
  }

  /**
   * Mostrar alerta
   */
  function showAlert(message, type) {
    if (!alertContainer) return;

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

  // Exponer función de logout globalmente
  window.logout = function () {
    auth.signOut().then(() => {
      localStorage.removeItem(CONFIG.STORAGE.GERENTE);
      localStorage.removeItem(CONFIG.STORAGE.TOKEN);
      window.location.href = 'index.html';
    }).catch((error) => {
      console.error('Error al cerrar sesión:', error);
    });
  };
});