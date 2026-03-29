-- =====================================================
-- CORRECCIÓN: Políticas RLS sin recursión infinita
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- Eliminar políticas problemáticas
DROP POLICY IF EXISTS "Admin full access profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Admin full access mora_config" ON mora_config;
DROP POLICY IF EXISTS "All can read mora_config" ON mora_config;
DROP POLICY IF EXISTS "Admin full access clients" ON clients;
DROP POLICY IF EXISTS "Cobrador can view clients" ON clients;
DROP POLICY IF EXISTS "Admin full access loans" ON loans;
DROP POLICY IF EXISTS "Cobrador can view loans" ON loans;
DROP POLICY IF EXISTS "Admin full access installments" ON installments;
DROP POLICY IF EXISTS "Cobrador can view installments" ON installments;
DROP POLICY IF EXISTS "Admin full access boxes" ON cash_boxes;
DROP POLICY IF EXISTS "Cobrador can view own box" ON cash_boxes;
DROP POLICY IF EXISTS "Admin full access movements" ON cash_box_movements;
DROP POLICY IF EXISTS "Cobrador can view own movements" ON cash_box_movements;
DROP POLICY IF EXISTS "Admin full access payments" ON payment_attempts;
DROP POLICY IF EXISTS "Cobrador can view own payments" ON payment_attempts;
DROP POLICY IF EXISTS "Admin full access deliveries" ON delivery_attempts;
DROP POLICY IF EXISTS "Cobrador can view own deliveries" ON delivery_attempts;
DROP POLICY IF EXISTS "Admin full access moras" ON moras;
DROP POLICY IF EXISTS "Cobrador can view moras" ON moras;

-- =====================================================
-- CREAR FUNCIÓN HELPER PARA VERIFICAR ROL
-- =====================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    -- Verificar si el usuario actual tiene rol admin en auth.metadata
    RETURN (
        SELECT COALESCE((current_setting('auth.metadata', true)::jsonb)->>'role', '') = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- NUEVAS POLÍTICAS SIMPLIFICADAS
-- =====================================================

-- profiles: todos pueden ver su propio perfil, admin puede hacer todo
CREATE POLICY "profiles_select_own" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_all" ON profiles
    FOR ALL USING (is_admin() = true);

-- mora_config: todos pueden leer, solo admin puede modificar
CREATE POLICY "mora_config_read" ON mora_config
    FOR SELECT USING (true);

CREATE POLICY "mora_config_all" ON mora_config
    FOR ALL USING (is_admin() = true);

-- clients: todos pueden ver activos, admin puede hacer todo
CREATE POLICY "clients_read_active" ON clients
    FOR SELECT USING (estado = 'activo' OR is_admin() = true);

CREATE POLICY "clients_all" ON clients
    FOR ALL USING (is_admin() = true);

-- loans: admin todo, cobradores ven activos
CREATE POLICY "loans_read" ON loans
    FOR SELECT USING (
        estado IN ('activo', 'mora', 'a_entregar') OR is_admin() = true
    );

CREATE POLICY "loans_all" ON loans
    FOR ALL USING (is_admin() = true);

-- installments: admin todo, cobradores ven de préstamos activos
CREATE POLICY "installments_read" ON installments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM loans l
            WHERE l.id = loan_id AND l.estado IN ('activo', 'mora', 'a_entregar')
        ) OR is_admin() = true
    );

CREATE POLICY "installments_all" ON installments
    FOR ALL USING (is_admin() = true);

-- cash_boxes: admin todo, cobradores ven su propia caja
CREATE POLICY "cash_boxes_read_own" ON cash_boxes
    FOR SELECT USING (cobrador_id = auth.uid() OR is_admin() = true);

CREATE POLICY "cash_boxes_all" ON cash_boxes
    FOR ALL USING (is_admin() = true);

-- cash_box_movements: admin todo, cobradores ven movimientos de su caja
CREATE POLICY "cash_box_movements_read" ON cash_box_movements
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM cash_boxes cb
            WHERE cb.id = box_id AND cb.cobrador_id = auth.uid()
        ) OR is_admin() = true
    );

CREATE POLICY "cash_box_movements_all" ON cash_box_movements
    FOR ALL USING (is_admin() = true);

-- payment_attempts: admin todo, cobradores ven los propios
CREATE POLICY "payment_attempts_read_own" ON payment_attempts
    FOR SELECT USING (cobrador_id = auth.uid() OR is_admin() = true);

CREATE POLICY "payment_attempts_all" ON payment_attempts
    FOR ALL USING (is_admin() = true);

-- delivery_attempts: admin todo, cobradores ven los propios
CREATE POLICY "delivery_attempts_read_own" ON delivery_attempts
    FOR SELECT USING (cobrador_id = auth.uid() OR is_admin() = true);

CREATE POLICY "delivery_attempts_all" ON delivery_attempts
    FOR ALL USING (is_admin() = true);

-- moras: admin todo, cobradores ven de préstamos activos
CREATE POLICY "moras_read" ON moras
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM installments i
            JOIN loans l ON l.id = i.loan_id
            WHERE i.id = installment_id AND l.estado IN ('activo', 'mora')
        ) OR is_admin() = true
    );

CREATE POLICY "moras_all" ON moras
    FOR ALL USING (is_admin() = true);

-- =====================================================
-- ACTUALIZAR ROL DE USUARIO EN AUTH.METADATA
-- =====================================================

-- Para que un usuario sea admin, ejecutar:
-- UPDATE auth.users SET raw_user_meta_data = jsonb_build_object('role', 'admin') WHERE email = 'tu_email@admin.com';

-- O si ya tienes usuarios, actualizar su metadata:
-- UPDATE auth.users SET raw_user_meta_data = jsonb_set(raw_user_meta_data, '{role}', '"admin"') WHERE id = 'uuid-del-usuario';

SELECT 'Políticas RLS actualizadas correctamente' AS resultado;
