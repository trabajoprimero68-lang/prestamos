-- Políticas RLS para loans - Solo admin puede modificar, todos pueden leer

-- Eliminar políticas existentes
DROP POLICY IF EXISTS "loans_read" ON loans;
DROP POLICY IF EXISTS "loans_all" ON loans;

-- Todos pueden leer préstamos activos
CREATE POLICY "loans_select" ON loans
    FOR SELECT USING (estado IN ('a_entregar', 'activo', 'mora') OR estado = 'pagado');

-- Solo admin puede crear, actualizar, eliminar
CREATE POLICY "loans_insert_admin" ON loans
    FOR INSERT WITH CHECK (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

CREATE POLICY "loans_update_admin" ON loans
    FOR UPDATE USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

CREATE POLICY "loans_delete_admin" ON loans
    FOR DELETE USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- =====================================================
-- Políticas para installments
-- =====================================================

DROP POLICY IF EXISTS "installments_read" ON installments;
DROP POLICY IF EXISTS "installments_all" ON installments;

CREATE POLICY "installments_select" ON installments
    FOR SELECT USING (true);

CREATE POLICY "installments_insert_admin" ON installments
    FOR INSERT WITH CHECK (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

CREATE POLICY "installments_update_admin" ON installments
    FOR UPDATE USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- =====================================================
-- Políticas para payment_attempts
-- =====================================================

DROP POLICY IF EXISTS "payments_read" ON payment_attempts;
DROP POLICY IF EXISTS "payments_all" ON payment_attempts;

CREATE POLICY "payments_select" ON payment_attempts
    FOR SELECT USING (cobrador_id = auth.uid());

CREATE POLICY "payments_insert" ON payment_attempts
    FOR INSERT WITH CHECK (true);

-- =====================================================
-- Políticas para delivery_attempts
-- =====================================================

DROP POLICY IF EXISTS "deliveries_read" ON delivery_attempts;
DROP POLICY IF EXISTS "deliveries_all" ON delivery_attempts;

CREATE POLICY "deliveries_select" ON delivery_attempts
    FOR SELECT USING (cobrador_id = auth.uid());

CREATE POLICY "deliveries_insert" ON delivery_attempts
    FOR INSERT WITH CHECK (true);

-- =====================================================
-- Políticas para moras
-- =====================================================

DROP POLICY IF EXISTS "moras_read" ON moras;
DROP POLICY IF EXISTS "moras_all" ON moras;

CREATE POLICY "moras_select" ON moras
    FOR SELECT USING (true);

CREATE POLICY "moras_insert_admin" ON moras
    FOR INSERT WITH CHECK (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

SELECT 'Políticas de préstamos, cuotas y cobros actualizadas ✅' AS resultado;
