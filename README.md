# ALE Gestión

Sistema de gestión de préstamos y cobros desarrollado con Flutter, Riverpod y Supabase.

## 🚀 Características

- **Gestión de Préstamos**: Registro y seguimiento de préstamos
- **Gestión de Cobros**: Control de cuotas con cálculo automático de moras
- **Cajas**: Control de caja con rendición diaria
- **Dashboard**: Vista diaria con listas de préstamos a entregar y cobrar
- **Roles**: Admin (completo) y Cobrador (operaciones)
- **Moras Automáticas**: Cálculo dinámico desde el 1er día de atraso

## 🛠️ Tech Stack

- **Flutter** 3.38.5 (gestionado con FVM)
- **Riverpod** - State Management
- **Supabase** - Backend (Auth + Database + RLS)
- **GoRouter** - Navegación
- **Clean Architecture** - Estructura del proyecto

## 📋 Requisitos Previos

1. **Flutter SDK** instalado via FVM
2. **Supabase** proyecto configurado
3. **Node.js** (opcional, para CLI de Supabase)

## ⚡ Instalación

### 1. Configurar FVM

```bash
# Instalar FVM si no lo tenés
flutter pub global activate fvm

# Instalar la versión de Flutter
fvm install 3.38.5

# Usar la versión del proyecto
fvm use 3.38.5
```

### 2. Instalar dependencias

```bash
fvm flutter pub get
```

### 3. Configurar Supabase

1. Crear un proyecto en [supabase.com](https://supabase.com)
2. Copiar el archivo `supabase/migrations/001_initial_schema.sql`
3. Ejecutar en el SQL Editor de Supabase Dashboard

### 4. Configurar credenciales

Editar `lib/core/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'TU_SUPABASE_URL';
static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
```

### 5. Ejecutar la app

```bash
fvm flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/     # Constantes de la app
│   ├── errors/        # Manejo de errores
│   ├── router/        # Configuración de rutas
│   ├── supabase/      # Cliente de Supabase
│   ├── theme/         # Tema de la app
│   └── utils/         # Utilidades compartidas
│
├── features/
│   ├── auth/          # Autenticación
│   ├── boxes/         # Gestión de cajas
│   ├── clients/      # Gestión de clientes
│   ├── dashboard/    # Dashboard principal
│   ├── loans/        # Préstamos
│   └── payments/     # Cobros y cuotas
│
└── main.dart         # Entry point
```

## 🔐 Reglas de Negocio

### Moras
- Se aplica desde el **1er día de atraso**
- Fórmula: `mora = mora_config.monto × días_de_atraso`
- Configurable desde el panel de Admin

### Flujo de Cobro
1. **Paga en fecha** → Sin mora
2. **No paga** → Mora automática inmediata desde día 1
3. **Cobrador no pudo ir** → "Diferir al siguiente día" sin mora

### Flujo de Entrega
1. **Editar fecha** → Reprogramar entrega
2. **Pasar al siguiente día** → Sin mora
3. **Se pasa de fecha** → Mora por atraso

### Cajas
- Solo Admin puede abrir/cerrar cajas
- Cobrador recibe caja con monto inicial
- Rendición diaria al cerrar

## 🧪 Tests

```bash
# Ejecutar todos los tests
fvm flutter test

# Ejecutar tests específicos
fvm flutter test test/core/utils/date_utils_test.dart
```

## 📝 Variables de Entorno

Para producción, considerar usar environment variables:

```dart
// lib/core/constants/app_constants.dart
static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'YOUR_SUPABASE_URL');
```

## 🤝 Contribuir

1. Fork del proyecto
2. Crear una rama (`git checkout -b feature/nueva-caracteristica`)
3. Commitear cambios (`git commit -m 'Agregar nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Crear un Pull Request

## 📄 Licencia

MIT License

## 👤 Autor

ALE Gestión - Sistema de Gestión de Préstamos
