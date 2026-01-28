# Documentación de Pantallas - App Tikit iOS

**Versión:** 1.1.1  
**Fecha:** 28 de enero de 2026  
**Base URL API:** `https://tikit.cl/api/`

---

## Índice
1. [LoginView](#1-loginview)
2. [MainView](#2-mainview)
3. [HomeView](#3-homeview)
4. [SessionsView](#4-sessionsview)
5. [CheckinsView](#5-checkinsview)
6. [QRScannerView](#6-qrscannerview)
7. [CheckinSuccessView](#7-checkinsuccessview)
8. [CheckinErrorView](#8-checkinerrorview)
9. [ProfileView](#9-profileview)
10. [Flujos de Datos](#flujos-de-datos)

---

## 1. LoginView

### Descripción
Pantalla de inicio de sesión con dos métodos de autenticación: email/contraseña y Google OAuth.

### Elementos de UI

#### Inputs:
- **Email (TextField)**
  - Tipo: `emailAddress`
  - Auto-capitalización: Deshabilitada
  - Placeholder: "Email"
  - Validación: Formato de email válido y campo requerido
  - Muestra error en rojo debajo del campo si la validación falla

- **Contraseña (SecureField/TextField)**
  - Placeholder: "Contraseña"
  - Validación: Campo requerido
  - Toggle para mostrar/ocultar contraseña (botón con ícono de ojo)
  - Muestra error en rojo debajo del campo si la validación falla

#### Botones:
- **Botón Google**
  - Ícono: Logo de Google
  - Texto: "Google"
  - Estilo: Borde gris, fondo transparente, forma de cápsula
  - Acción: Inicia Google OAuth
  
- **Botón "Iniciar sesión"**
  - Color: Brand Primary (#B6287E)
  - Forma: Cápsula
  - Estado: Muestra ProgressView cuando está cargando
  - Acción: Envía credenciales al servidor

#### Elementos Visuales:
- Logo de Tikit (cambia según tema claro/oscuro)
- Título: "Bienvenido a Tikit"
- Subtítulo: "Tu administrador de eventos"
- Toast de error en la parte inferior (temporal, 3 segundos)

### Interacciones con API

#### 1. Login con Email/Contraseña
**Endpoint:** `POST /auth/login`

**Headers:**
```
Content-Type: application/json
```

**Payload:**
```json
{
  "email": "usuario@example.com",
  "password": "contraseña123"
}
```

**Respuesta Exitosa (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "firstName": "Juan",
    "lastName": "Pérez",
    "email": "juan@example.com",
    "phone": "+56912345678",
    "company": "Empresa Demo",
    "position": "Gerente",
    "country": "Chile",
    "state": "Metropolitana",
    "role": "role_admin",
    "imageUrl": "https://tikit.cl/uploads/profile.jpg"
  }
}
```

**Respuesta de Error (4xx):**
```json
{
  "message": "Credenciales inválidas",
  "errors": {
    "email": ["Email inválido"],
    "password": ["Contraseña requerida"]
  }
}
```

**Qué hace con los datos:**
- Guarda `token` y `refresh_token` en `UserDefaults`
- Guarda el perfil de usuario en `UserDefaults`
- Actualiza `SessionManager.isLoggedIn = true`
- Navega automáticamente a `MainView`

#### 2. Login con Google OAuth
**Endpoint:** `POST /auth/social-login`

**Headers:**
```
Content-Type: application/json
```

**Payload:**
```json
{
  "provider": "google",
  "token": "ya29.a0AfH6SMBx..."
}
```

**Respuesta:** Misma estructura que login con email/contraseña

**Flujo:**
1. Abre Google Sign-In nativo
2. Obtiene `accessToken` de Google
3. Envía el token a la API de Tikit
4. Guarda los datos de sesión igual que el login tradicional

---

## 2. MainView

### Descripción
Vista principal con navegación por pestañas (TabView) que contiene las dos secciones principales de la app.

### Elementos de UI

#### Pestañas:
1. **Pestaña "Eventos"**
   - Ícono: `list.bullet`
   - Vista: `HomeView`
   
2. **Pestaña "Mi cuenta"**
   - Ícono: `person`
   - Vista: `ProfileView`

### Interacciones con API
No tiene interacciones directas con la API. Actúa como contenedor de navegación.

---

## 3. HomeView

### Descripción
Lista de eventos activos con búsqueda y navegación a sesiones. Implementa scroll infinito para cargar más eventos.

### Elementos de UI

#### Inputs:
- **Barra de búsqueda**
  - Placeholder: "Buscar eventos"
  - Filtrado local por nombre de evento (case-insensitive)

#### Elementos Visuales:
- **EventCard (por cada evento):**
  - Imagen de portada (16:9)
  - Nombre del evento (máximo 2 líneas)
  - Fecha del evento con ícono de calendario
  - Ubicación con ícono de pin (si existe)
  - Categorías (máximo 3, scroll horizontal)
  - Badges informativos:
    - Tipo de acceso (Libre/Pago) - verde/naranja
    - Estado (Activo/Inactivo) - verde/gris
    - Cantidad de registrados - morado
  - Es clickeable y navega a `SessionsView`

#### Navegación:
- Título: "Eventos"
- Pull-to-refresh disponible

### Interacciones con API

#### Obtener Lista de Eventos
**Endpoint:** `GET /events`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
```
page=1
query=
order=startDate:ASC
isActive=true
limit=100
order=id:DESC
filter=[]
```

**Respuesta Exitosa (200):**
```json
{
  "data": [
    {
      "id": 6,
      "name": "Tech Summit 2026",
      "accessType": "ACCESS_TYPE_FREE",
      "isActive": true,
      "createdAt": "2025-01-15T10:00:00Z",
      "startDate": "2026-03-01T00:00:00Z",
      "endDate": "2026-03-03T23:59:59Z",
      "place": "Centro de Convenciones",
      "address": "Av. Principal 123",
      "addressCity": "Santiago",
      "categories": [
        {
          "id": 1,
          "name": "Tecnología"
        }
      ],
      "landingMedia": [
        {
          "id": 10,
          "path": "/uploads/events/cover.jpg",
          "isDefault": true
        }
      ],
      "registrantsCount": 150,
      "description": "Evento de tecnología...",
      "slug": "tech-summit-2026"
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 100,
    "total_items": 250,
    "total_pages": 3
  }
}
```

**Qué hace con los datos:**
- Decodifica a array de `Event`
- Agrega eventos al array existente (scroll infinito)
- Incrementa `currentPage` para próxima carga
- Formatea fecha de inicio con `DateFormatter` español
- Construye URL de imagen (prefijo https://tikit.cl si no es URL completa)
- Muestra cada evento en un `EventCard`

**Lógica de Scroll Infinito:**
- Se activa al llegar al último elemento
- Carga la siguiente página mientras `currentPage <= totalPages`
- Previene cargas duplicadas con flag `isFetching`

---

## 4. SessionsView

### Descripción
Lista de sesiones de un evento específico. Se accede navegando desde un evento en `HomeView`.

### Elementos de UI

#### Header Compacto:
- Nombre del evento (headline)
- Badges informativos del evento:
  - Tipo de acceso (Libre/Pago)
  - Estado (Activo/Inactivo)
  - Cantidad de registrados

#### Elementos Visuales:
- **SessionCard (por cada sesión):**
  - Nombre de la sesión (headline)
  - Chevron derecho (indica navegación)
  - Fechas de inicio y fin con formato "dd MMM yyyy HH:mm"
  - Lista de tipos de registrante con:
    - Nombre de la categoría
    - Contador: "checkins/registrados"
    - Barra de progreso visual (verde)
  - Es clickeable y navega a `CheckinsView`

#### Estados:
- Loader mientras carga
- Mensaje "No hay sesiones disponibles" con ícono si no hay data

### Interacciones con API

#### Obtener Sesiones de un Evento
**Endpoint:** `GET /events/{eventId}/sessions`

**Headers:**
```
Authorization: Bearer {token}
```

**Respuesta Exitosa (200):**
```json
{
  "eventId": 6,
  "eventName": "Tech Summit 2026",
  "sessions": [
    {
      "id": 12,
      "name": "Día 1 - Mañana",
      "description": "Sesión matutina del primer día",
      "createdAt": "2025-01-15T10:00:00Z",
      "updatedAt": "2025-01-20T15:30:00Z",
      "isDefault": false,
      "startDate": "2026-03-01T00:00:00Z",
      "startTime": "2026-03-01T09:00:00Z",
      "endDate": "2026-03-01T00:00:00Z",
      "endTime": "2026-03-01T13:00:00Z",
      "registrantTypes": [
        {
          "sessionRegistrantTypeId": 45,
          "registrantTypeId": 3,
          "registrantTypeName": "VIP",
          "price": 50000,
          "stock": 100,
          "used": 75,
          "available": 25,
          "isActive": true,
          "registered": 80,
          "checkins": 60,
          "attendancePercentage": 75.0
        }
      ]
    }
  ],
  "totalSessions": 4
}
```

**Qué hace con los datos:**
- Decodifica a `SessionsResponse`
- Extrae array de `EventSession`
- Muestra cada sesión en un `SessionCard`
- Para cada `SessionRegistrantType`:
  - Calcula progreso visual: `checkins / registered * 100%`
  - Muestra barra de progreso proporcional al ancho disponible
- Formatea fechas con `DateFormatter` español
- Pasa `EventSession` completa a `CheckinsView` al navegar

---

## 5. CheckinsView

### Descripción
Pantalla principal de check-ins de una sesión específica. Permite ver check-ins realizados y registrar nuevos mediante QR.

### Elementos de UI

#### Header Compacto:
- Nombre de la sesión con círculo de marca (brand primary)
- Fechas de inicio y fin de la sesión

#### Contador:
- Texto: "Check-ins (X/Y)"
  - X = Check-ins realizados en esta sesión
  - Y = Total de registrados en esta sesión

#### Lista de Check-ins:
- **CheckinCard (por cada check-in):**
  - Nombre completo del invitado (headline)
  - Badge con tipo de acceso (e.g., "VIP", "General") - color brand primary
  - Badge de método (con checkmark verde) - e.g., "QR"
  - Fecha y hora del check-in con ícono de calendario
  - Es clickeable y muestra detalles en modal

#### Botón Flotante:
- **Botón de escanear QR**
  - Posición: Inferior derecha
  - Ícono: `qrcode.viewfinder`
  - Color: Brand Primary
  - Forma: Círculo con sombra
  - Acción: Abre `QRScannerView` en fullscreen

#### Estados:
- Loader mientras carga check-ins
- Mensaje "Sin check-ins aún" con ícono si no hay data

### Interacciones con API

#### 1. Obtener Check-ins de una Sesión
**Endpoint:** `GET /checkins`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
```
page=1
query=
limit=100
order=id:DESC
filter=[{"field":"e.event","operator":"=","value":6},{"field":"e.eventSession","operator":"=","value":12}]
```

**Respuesta Exitosa (200):**
```json
{
  "data": [
    {
      "id": 234,
      "guest": {
        "id": 56,
        "firstName": "María",
        "lastName": "González",
        "email": "maria@example.com",
        "registrantType": {
          "id": 3,
          "name": "VIP"
        }
      },
      "eventSession": {
        "id": 12,
        "name": "Día 1 - Mañana"
      },
      "method": "QR",
      "latitude": -33.4569,
      "longitude": -70.6483,
      "createdAt": "2026-03-01T09:15:30Z",
      "updatedAt": "2026-03-01T09:15:30Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 100,
    "total_items": 60,
    "total_pages": 1
  }
}
```

**Qué hace con los datos:**
- Decodifica a `CheckinsResponse`
- Extrae array de `CheckinData`
- Muestra cada check-in en un `CheckinCard`
- Formatea `createdAt` con formato "dd MMM yyyy HH:mm"
- Calcula totales para el contador
- Al hacer tap en un card, muestra modal `CheckinSuccessView` con detalles

#### 2. Registrar Check-in
**Endpoint:** `POST /checkins/register`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Payload:**
```json
{
  "event": 6,
  "eventSession": 12,
  "guest": "encrypted_qr_code_string"
}
```

**Respuesta Exitosa (201):**
```json
{
  "id": 235,
  "guest": {
    "id": 57,
    "firstName": "Carlos",
    "lastName": "Ramírez",
    "email": "carlos@example.com",
    "registrantType": {
      "id": 3,
      "name": "VIP"
    }
  },
  "eventSession": {
    "id": 12,
    "name": "Día 1 - Mañana"
  },
  "method": "QR",
  "latitude": null,
  "longitude": null,
  "createdAt": "2026-03-01T10:30:45Z",
  "updatedAt": "2026-03-01T10:30:45Z"
}
```

**Respuesta de Error (4xx):**
```json
{
  "message": "Guest has already checked in for this session",
  "error": "Guest has already checked in for this session"
}
```

**Mensajes de error traducidos:**
- "Invalid data" → "Datos inválidos"
- "Not found" → "No encontrado"
- "Guest is not registered in this event" → "El invitado no está registrado en este evento"
- "Guest is not registered in this session" → "El invitado no está registrado en esta sesión"
- "Guest has already checked in for this session" → "El invitado ya ha realizado check-in en esta sesión"

**Qué hace con los datos:**

**Caso Exitoso (201):**
1. Reproduce sonido de sistema (ID 1108)
2. Convierte `CheckinResponse` a `CheckinData`
3. Inserta el nuevo check-in al inicio del array local
4. Muestra modal `CheckinSuccessView` con:
   - Datos del invitado
   - Tipo de acceso
   - Método y hora
   - Nombre de sesión y evento

**Caso Error:**
1. Decodifica `CheckinAPIErrorResponse`
2. Traduce el mensaje de error
3. Muestra modal `CheckinErrorView` con mensaje traducido
4. Log detallado en consola (OSLog)

**Logging:**
- Logs de request completa (URL, headers, payload)
- Logs de response (status code, body)
- Logs de traducción de mensajes
- Usa subsystem: "com.tikit", category: "CheckinsView"

---

## 6. QRScannerView

### Descripción
Vista de escaneo de códigos QR usando la cámara del dispositivo. Se presenta como fullscreen cover.

### Elementos de UI

#### Cámara:
- Vista de cámara en tiempo real (AVCaptureSession)
- Detección automática de códigos QR
- Preview layer ocupa toda la pantalla

#### Botones:
- **Botón Cancelar (X)**
  - Posición: Esquina superior derecha
  - Ícono: `xmark.circle.fill`
  - Color: Blanco con fondo negro semitransparente
  - Acción: Cierra el scanner y vuelve a `CheckinsView`
  
- **Botón Linterna**
  - Posición: Esquina inferior izquierda
  - Ícono: `flashlight.off.fill` / `flashlight.on.fill`
  - Color: Blanco (apagada) / Amarillo (encendida)
  - Fondo: Negro semitransparente
  - Acción: Toggle del flash de la cámara
  - Solo visible si el dispositivo tiene linterna

#### Permisos Requeridos:
- Acceso a la cámara (NSCameraUsageDescription en Info.plist)

### Interacciones con API
No interactúa directamente con API. Retorna el código QR escaneado mediante callback a `CheckinsView`, que luego hace el POST a `/checkins/register`.

**Flujo:**
1. Usuario presiona botón de escanear en `CheckinsView`
2. Se abre QRScannerView en fullscreen
3. Usuario apunta la cámara al código QR
4. Se detecta el código automáticamente
5. Se detiene la cámara
6. Se cierra el scanner
7. Se ejecuta callback `completion` con el código
8. `CheckinsView` recibe el código y hace el POST de registro

**Manejo de Errores:**
- Si no puede acceder a la cámara: muestra alerta
- Si no puede preparar el input: muestra alerta
- Si no puede configurar el output: muestra alerta
- Si no puede leer el código: muestra alerta

---

## 7. CheckinSuccessView

### Descripción
Modal que muestra el resultado exitoso de un check-in. Puede ser invocado después de escanear QR o al hacer tap en un check-in existente.

### Elementos de UI

#### Header:
- Ícono: Checkmark circular verde (grande, 60pt)
- Título: "Check-in Exitoso"
- Subtítulo: "Método: {método}" (e.g., "QR")
- Fecha y hora del check-in
- Fondo: Verde suave (opacity 0.1)

#### Sección Invitado:
- **Fila 1:** Ícono persona + "Invitado" + Nombre completo
- **Fila 2:** Ícono envelope + "Email" + Email del invitado

#### Divider

#### Sección Acceso:
- **Fila 1:** Ícono ticket + "Tipo de Acceso" + Tipo (e.g., "VIP")
- **Fila 2:** Ícono calendario + "Sesión" + Nombre de sesión
- **Fila 3:** Ícono mappin + "Evento" + Nombre de evento

#### Botón:
- **Botón "Cerrar"**
  - Color: Azul
  - Forma: Rounded rectangle
  - Posición: Parte inferior
  - Acción: Cierra el modal

### Interacciones con API
No tiene. Recibe todos los datos ya procesados desde `CheckinsView`.

**Datos recibidos:**
- `CheckinResponse`: Datos completos del check-in
- `SessionRegistrantType`: Tipo de acceso del invitado (opcional)
- `sessionName`: Nombre de la sesión (String)
- `eventName`: Nombre del evento (String)
- `onDismiss`: Callback para cerrar

---

## 8. CheckinErrorView

### Descripción
Modal que muestra errores al intentar hacer check-in (duplicados, no registrado, etc.).

### Elementos de UI

#### Header:
- Ícono: X circular rojo (grande, 60pt)
- Título: Recibido como parámetro (e.g., "Error de Check-in")
- Fondo: Rojo suave (opacity 0.1)

#### Mensaje de Error:
- Ícono: Triángulo con exclamación (rojo)
- Texto del mensaje: Recibido como parámetro (ya traducido)
- Permite múltiples líneas

#### Botón:
- **Botón "Cerrar"**
  - Color: Rojo
  - Forma: Rounded rectangle
  - Posición: Parte inferior
  - Acción: Cierra el modal

### Interacciones con API
No tiene. Recibe el mensaje de error ya traducido desde `CheckinsView`.

**Datos recibidos:**
- `title`: Título del error (String)
- `message`: Mensaje descriptivo del error (String)
- `onDismiss`: Callback para cerrar

---

## 9. ProfileView

### Descripción
Perfil del usuario logueado con información personal y opción de cerrar sesión.

### Elementos de UI

#### Header (con gradiente):
- **Avatar:**
  - Circular (120x120)
  - Muestra imagen de perfil si existe (`imageUrl`)
  - Ícono de persona genérico si no hay imagen
  - Borde blanco semitransparente
  - Sombra
- **Nombre completo:** `firstName + lastName`
- **Rol:** Capitalizado (oculta "role_admin" para no exponer privilegios)
- Fondo: Gradiente de Brand Primary a Brand Secondary

#### Tarjeta de Información:
- Título: "Datos personales"
- **Filas de datos:**
  - Ícono persona + "Nombre" + `firstName`
  - Ícono rectángulo + "Apellido" + `lastName`
  - Ícono envelope + "Email" + `email`
- Fondo: Blanco/Sistema con sombra
- Esquinas redondeadas

#### Botón:
- **Botón "Cerrar sesión"**
  - Ícono: `rectangle.portrait.and.arrow.right`
  - Color de fondo: Blanco con opacity
  - Color de texto: Brand Primary
  - Forma: Rounded rectangle
  - Acción: Ejecuta `session.logout()`

### Interacciones con API

#### Obtener Perfil (automático al login)
**Endpoint:** `GET /auth/me`

**Headers:**
```
Authorization: Bearer {token}
```

**Respuesta Exitosa (200):**
```json
{
  "id": 1,
  "firstName": "Juan",
  "lastName": "Pérez",
  "email": "juan@example.com",
  "phone": "+56912345678",
  "company": "Empresa Demo",
  "position": "Gerente",
  "country": "Chile",
  "state": "Metropolitana",
  "role": "role_admin",
  "imageUrl": "https://tikit.cl/uploads/profile.jpg"
}
```

**Qué hace con los datos:**
- Se ejecuta automáticamente después de login exitoso (si no viene en el response de login)
- Decodifica a `UserProfile`
- Guarda en `SessionManager.user`
- Persiste en `UserDefaults` como JSON
- Se muestra en esta vista
- La vista lee directamente desde `SessionManager.user` (no hace request propia)

**Logout:**
- No hace request al servidor
- Borra `token`, `refreshToken` y `user` de memoria
- Borra todo de `UserDefaults`
- Actualiza `SessionManager.isLoggedIn = false`
- La app automáticamente muestra `LoginView` por reacción al estado

---

## Flujos de Datos

### 1. Autenticación y Gestión de Sesión

#### SessionManager (ObservableObject):
- **Estado publicado:**
  - `isLoggedIn`: Bool
  - `token`: String? (JWT)
  - `refreshToken`: String? (JWT refresh)
  - `user`: UserProfile?

- **Persistencia:** UserDefaults
  - Key "token"
  - Key "refreshToken"
  - Key "userProfile" (JSON codificado)

- **Refresh Token Automático:**
  - Se ejecuta en `init()` si hay sesión guardada
  - NetworkManager intercepta 401 y ejecuta refresh automático
  - Si refresh falla, hace logout automático

#### NetworkManager (Singleton):
- Wrapper de URLSession
- Manejo automático de 401:
  1. Detecta status code 401
  2. Llama a `SessionManager.refreshAuthToken()`
  3. Si éxito: reintenta request original con nuevo token
  4. Si falla: ejecuta logout
- Actualiza header Authorization con token actual en cada request

### 2. Navegación Principal

```
TikitApp
  └─ SessionManager (EnvironmentObject)
      └─ ContentView (router)
          ├─ LoginView (si !isLoggedIn)
          └─ MainView (si isLoggedIn)
              ├─ Tab 1: HomeView
              │   └─ EventsViewModel
              │       └─ Navegación: SessionsView
              │           └─ Navegación: CheckinsView
              │               ├─ FullScreenCover: QRScannerView
              │               ├─ Sheet: CheckinSuccessView
              │               └─ Sheet: CheckinErrorView
              └─ Tab 2: ProfileView
```

### 3. Modelos de Datos

#### Event.swift:
- `Event`: Evento principal
- `Category`: Categorías del evento
- `LandingMedia`: Imágenes del evento
- `SessionRegistrantType`: Tipos de acceso con stock y check-ins
- `RegistrantType`: Tipo de registrante base
- `EventsResponse`: Wrapper con data y paginación
- `SessionsResponse`: Wrapper con sesiones de un evento
- `EventSession`: Sesión individual

#### CheckinModels.swift:
- `CheckinResponse`: Respuesta al crear check-in
- `CheckinResponse.Guest`: Datos del invitado
- `CheckinResponse.EventSessionInfo`: Info de la sesión
- `CheckinData`: Check-in individual en lista
- `CheckinsResponse`: Wrapper con data y paginación
- `CheckinPagination`: Info de paginación
- `CheckinAPIErrorResponse`: Errores de API

#### SessionManager.swift:
- `AuthResponse`: Respuesta de login/social-login
- `UserProfile`: Perfil de usuario

#### APIError.swift:
- `APIErrorResponse`: Error genérico con message y errors (campo → array de errores)

### 4. Constantes y Configuración

#### APIConstants.swift:
```swift
baseURL = "https://tikit.cl/api/"
```

#### Colors.swift:
```swift
brandPrimary = #B6287E (RGB: 182, 40, 126)
brandSecondary = #5E38E2 (RGB: 94, 56, 226)
```

#### Google OAuth:
```swift
clientID = "331974773758-28bc8jhftlnhvq3r5s7okb6agh2rflfu.apps.googleusercontent.com"
```

### 5. Patrones de Codificación

#### Async/Await:
- Todas las llamadas de red usan async/await
- ViewModels marcan métodos con `@MainActor` para updates de UI
- Task { } para ejecutar código async desde sync context

#### Decodificación JSON:
- Todos los modelos implementan `Codable`
- Uso de `CodingKeys` para mapear snake_case (API) → camelCase (Swift)
- Ejemplo: `refresh_token` → `refreshToken`

#### Error Handling:
- Try-catch en todas las requests
- Decodificación de APIErrorResponse en status codes != 200
- Traducción de mensajes de error en español
- Logs con OSLog en operaciones críticas

#### State Management:
- `@Published` para propiedades reactivas
- `@EnvironmentObject` para SessionManager global
- `@StateObject` para ViewModels locales
- `@State` para estado local de vista

---

## Notas Técnicas

### Refresh Token Flow:
1. Request recibe 401
2. NetworkManager intercepta
3. POST a `/auth/refresh` con `refresh_token`
4. Guarda nuevo `token` y `refresh_token`
5. Reintenta request original
6. Si refresh falla → logout

### Paginación:
- HomeView implementa scroll infinito
- Carga automática al llegar al último elemento
- Previene cargas duplicadas con flag `isFetching`
- CheckinsView por ahora carga todos (limit=100)

### Formato de Fechas:
- API usa ISO8601 (UTC)
- App formatea a "dd MMM yyyy" o "dd MMM yyyy HH:mm"
- Locale español: "es_ES"

### Imágenes:
- URLs relativas se convierten a absolutas con prefijo `https://tikit.cl`
- AsyncImage con placeholder y manejo de errores
- Avatares usan ícono genérico si no hay imageUrl

### Seguridad:
- JWT Bearer tokens en todos los requests autenticados
- Refresh token strategy para no exponer token principal
- Google OAuth con clientID específico
- Códigos QR encriptados en el servidor

---

## Dependencias Externas

### Swift Package Manager:
- **GoogleSignIn-iOS** (v7.0.0+)
  - Repositorio: https://github.com/google/GoogleSignIn-iOS.git
  - Usado en: LoginView, SessionManager

### Frameworks iOS:
- SwiftUI
- Combine
- AVFoundation (para QR Scanner)
- AudioToolbox (para sonidos de sistema)
- OSLog (para logging)

---

## Configuración Requerida

### Info.plist:
- `NSCameraUsageDescription`: "Se requiere acceso a la cámara para escanear códigos QR de check-in."

### Entitlements (Tikit.entitlements):
- App Sandbox habilitado
- Hardened Runtime habilitado
- User Selected Files (read-only)

### Build Settings:
- iOS Deployment Target: 18.2
- Marketing Version: 1.1.1
- Current Project Version: 111
- Bundle Identifier: com.tikit.event

---

**Fin de la documentación**
