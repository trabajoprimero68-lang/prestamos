-- =====================================================
-- ALE GESTIÓN - Schema Inicial
-- Gestión de Préstamos y Cobros
-- =====================================================

-- =====================================================
-- EXTENSIONS
-- =====================================================

-- Habilitar UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- ENUMS
-- =====================================================

-- Estados de cliente
CREATE TYPE client_status AS ENUM ('activo', 'inactivo');

-- Estados de préstamo
CREATE TYPE loan_status AS ENUM ('a_entregar', 'activo', 'pagado', 'mora');

-- Estados de cuota
CREATE TYPE installment_status AS ENUM ('pendiente', 'pagada', 'vencida');

-- Estados de caja
CREATE TYPE box_status AS ENUM ('abierta', 'cerrada');

-- Tipos de movimiento de caja
CREATE TYPE movement_type AS ENUM ('apertura', 'cobro', 'rendicion', 'ajuste');

-- Resultados de intento de cobro
CREATE TYPE payment_result AS ENUM ('pagado', 'no_pagado', 'diferir');

-- Resultados de intento de entrega
CREATE TYPE delivery_result AS ENUM ('entregado', 'no_entregado', 'diferir');

-- Roles de usuario
CREATE TYPE user_role AS ENUM ('admin', 'cobrador');

-- =====================================================
-- TABLA: profiles (extiende auth.users)
-- =====================================================

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'cobrador',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABLA: mora_config (configuración de mora)
-- =====================================================

CREATE TABLE IF NOT EXISTS mora_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    monto DECIMAL(10,2) NOT NULL DEFAULT 50.00,
    activo BOOLEAN NOT NULL DEFAULT true,
    descripcion TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insertar configuración por defecto
INSERT INTO mora_config (monto, descripcion) 
VALUES (50.00, 'Monto por día de atraso');

-- =====================================================
-- TABLA: clients (clientes/deudores)
-- =====================================================

CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre TEXT NOT NULL,
    telefono TEXT,
    direccion TEXT,
    documento TEXT,
    estado client_status NOT NULL DEFAULT 'activo',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABLA: loans (préstamos)
-- =====================================================

CREATE TABLE IF NOT EXISTS loans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
    monto DECIMAL(12,2) NOT NULL,
    interes DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    cantidad_cuotas INTEGER NOT NULL DEFAULT 1,
    monto_cuota DECIMAL(12,2) NOT NULL,
    fecha_inicio DATE NOT NULL,
    estado loan_status NOT NULL DEFAULT 'a_entregar',
    fecha_entrega DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABLA: installments (cuotas)
-- =====================================================

CREATE TABLE IF NOT EXISTS installments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    numero_cuota INTEGER NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    monto_pagado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    fecha_vencimiento DATE NOT NULL,
    fecha_pago DATE,
    mora_aplicada DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado installment_status NOT NULL DEFAULT 'pendiente',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABLA: cash_boxes (cajas)
-- =====================================================

CREATE TABLE IF NOT EXISTS cash_boxes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cobrador_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    initial_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    current_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado box_status NOT NULL DEFAULT 'abierta',
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABLA: cash_box_movements (movimientos de caja)
-- =====================================================

CREATE TABLE IF NOT EXISTS cash_box_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    box_id UUID NOT NULL REFERENCES cash_boxes(id) ON DELETE CASCADE,
    type movement_type NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABLA: payment_attempts (intentos de cobro)
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    installment_id UUID NOT NULL REFERENCES installments(id) ON DELETE RESTRICT,
    cobrador_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    resultado payment_result NOT NULL,
    monto_cobrado DECIMAL(12,2),
    mora_del_dia DECIMAL(12,2) DEFAULT 0.00,
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABLA: delivery_attempts (intentos de entrega)
-- =====================================================

CREATE TABLE IF NOT EXISTS delivery_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE RESTRICT,
    cobrador_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    resultado delivery_result NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABLA: moras (registro de moras aplicadas)
-- =====================================================

CREATE TABLE IF NOT EXISTS moras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    installment_id UUID NOT NULL REFERENCES installments(id) ON DELETE RESTRICT,
    monto DECIMAL(12,2) NOT NULL,
    dias_atraso INTEGER NOT NULL,
    fecha_aplicacion DATE NOT NULL DEFAULT CURRENT_DATE,
    esta_pagada BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_loans_client_id ON loans(client_id);
CREATE INDEX IF NOT EXISTS idx_loans_estado ON loans(estado);
CREATE INDEX IF NOT EXISTS idx_installments_loan_id ON installments(loan_id);
CREATE INDEX IF NOT EXISTS idx_installments_estado ON installments(estado);
CREATE INDEX IF NOT EXISTS idx_installments_fecha_vencimiento ON installments(fecha_vencimiento);
CREATE INDEX IF NOT EXISTS idx_cash_boxes_cobrador_id ON cash_boxes(cobrador_id);
CREATE INDEX IF NOT EXISTS idx_cash_boxes_estado ON cash_boxes(estado);
CREATE INDEX IF NOT EXISTS idx_payment_attempts_installment_id ON payment_attempts(installment_id);
CREATE INDEX IF NOT EXISTS idx_payment_attempts_fecha ON payment_attempts(fecha);
CREATE INDEX IF NOT EXISTS idx_moras_installment_id ON moras(installment_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mora_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_boxes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_box_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE moras ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES - profiles
-- =====================================================

-- Admin puede ver y editar todos los perfiles
CREATE POLICY "Admin full access profiles" ON profiles
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Todos pueden ver su propio perfil
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- =====================================================
-- RLS POLICIES - mora_config
-- =====================================================

-- Solo admin puede modificar configuración de mora
CREATE POLICY "Admin full access mora_config" ON mora_config
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Todos pueden leer la configuración
CREATE POLICY "All can read mora_config" ON mora_config
    FOR SELECT
    TO authenticated
    USING (true);

-- =====================================================
-- RLS POLICIES - clients
-- =====================================================

-- Admin acceso total
CREATE POLICY "Admin full access clients" ON clients
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Cobrador puede ver clientes
CREATE POLICY "Cobrador can view clients" ON clients
    FOR SELECT
    TO authenticated
    USING (estado = 'activo');

-- =====================================================
-- RLS POLICIES - loans
-- =====================================================

-- Admin acceso total
CREATE POLICY "Admin full access loans" ON loans
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Cobrador puede ver préstamos activos
CREATE POLICY "Cobrador can view loans" ON loans
    FOR SELECT
    TO authenticated
    USING (estado IN ('activo', 'mora', 'a_entregar'));

-- =====================================================
-- RLS POLICIES - installments
-- =====================================================

-- Admin acceso total
CREATE POLICY "Admin full access installments" ON installments
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Cobrador puede ver cuotas de préstamos activos
CREATE POLICY "Cobrador can view installments" ON installments
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM loans l
            WHERE l.id = loan_id AND l.estado IN ('activo', 'mora')
        )
    );

-- =====================================================
-- RLS POLICIES - cash_boxes
-- =====================================================

-- Admin acceso total
CREATE POLICY "Admin full access boxes" ON cash_boxes
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Cobrador puede ver su propia caja
CREATE POLICY "Cobrador can view own box" ON cash_boxes
    FOR SELECT
    TO authenticated
    USING (cobrador_id = auth.uid());

-- =====================================================
-- RLS POLICIES - cash_box_movements
-- =====================================================

-- Admin acceso total
CREATE POLICY "Admin full access movements" ON cash_box_movements
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Cobrador puede ver movimientos de su caja
CREATE POLICY "Cobrador can view own movements" ON cash_box_movements
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM cash_boxes cb
            WHERE cb.id = box_id AND cb.cobrador_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - payment_attempts
-- =====================================================

-- Admin acceso total
CREATE POLICY "Admin full access payments" ON payment_attempts
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Cobrador puede ver sus propios intentos
CREATE POLICY "Cobrador can view own payments" ON payment_attempts
    FOR SELECT
    TO authenticated
    USING (cobrador_id = auth.uid());

-- =====================================================
-- RLS POLICIES - delivery_attempts
-- =====================================================

-- Admin acceso total
CREATE POLICY "Admin full access deliveries" ON delivery_attempts
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Cobrador puede ver sus propias entregas
CREATE POLICY "Cobrador can view own deliveries" ON delivery_attempts
    FOR SELECT
    TO authenticated
    USING (cobrador_id = auth.uid());

-- =====================================================
-- RLS POLICIES - moras
-- =====================================================

-- Admin acceso total
CREATE POLICY "Admin full access moras" ON moras
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Cobrador puede ver moras de préstamos activos
CREATE POLICY "Cobrador can view moras" ON moras
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM installments i
            JOIN loans l ON l.id = i.loan_id
            WHERE i.id = installment_id AND l.estado IN ('activo', 'mora')
        )
    );

-- =====================================================
-- FUNCTION: Trigger para crear perfil automáticamente
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (NEW.id, NEW.email, 'cobrador');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- FUNCTION: Actualizar estado de cuota automáticamente
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_installment_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'pagada' AND OLD.estado != 'pagada' THEN
        UPDATE installments
        SET fecha_pago = CURRENT_DATE,
            updated_at = NOW()
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Calcular mora automáticamente
-- =====================================================

CREATE OR REPLACE FUNCTION public.calculate_mora(p_installment_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_mora_config DECIMAL(10,2);
    v_dias_atraso INTEGER;
    v_mora DECIMAL(10,2);
BEGIN
    -- Obtener configuración de mora
    SELECT monto INTO v_mora_config
    FROM mora_config
    WHERE activo = true
    ORDER BY created_at DESC
    LIMIT 1;

    -- Si no hay config, usar 50 por defecto
    v_mora_config := COALESCE(v_mora_config, 50.00);

    -- Calcular días de atraso
    SELECT CURRENT_DATE - fecha_vencimiento INTO v_dias_atraso
    FROM installments
    WHERE id = p_installment_id;

    -- Si ya venció, calcular mora
    IF v_dias_atraso > 0 THEN
        v_mora := v_mora_config * v_dias_atraso;
    ELSE
        v_mora := 0;
    END IF;

    RETURN v_mora;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FIN DEL SCHEMA
-- =====================================================
