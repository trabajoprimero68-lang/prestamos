-- Políticas de cash_boxes para solo admin
-- Tabla: cash_boxes

-- SELECT: solo admin puede ver todas las cajas
DROP POLICY IF EXISTS "cash_boxes_select_admin" ON cash_boxes;
CREATE POLICY "cash_boxes_select_admin" ON cash_boxes
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- INSERT: solo admin
DROP POLICY IF EXISTS "cash_boxes_insert_admin" ON cash_boxes;
CREATE POLICY "cash_boxes_insert_admin" ON cash_boxes
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- UPDATE: solo admin
DROP POLICY IF EXISTS "cash_boxes_update_admin" ON cash_boxes;
CREATE POLICY "cash_boxes_update_admin" ON cash_boxes
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- DELETE: solo admin
DROP POLICY IF EXISTS "cash_boxes_delete_admin" ON cash_boxes;
CREATE POLICY "cash_boxes_delete_admin" ON cash_boxes
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- =====================================================
-- Tabla: cash_box_movements

-- SELECT: solo admin puede ver todos los movimientos
DROP POLICY IF EXISTS "cash_box_movements_select_admin" ON cash_box_movements;
CREATE POLICY "cash_box_movements_select_admin" ON cash_box_movements
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- INSERT: solo admin
DROP POLICY IF EXISTS "cash_box_movements_insert_admin" ON cash_box_movements;
CREATE POLICY "cash_box_movements_insert_admin" ON cash_box_movements
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- UPDATE: solo admin
DROP POLICY IF EXISTS "cash_box_movements_update_admin" ON cash_box_movements;
CREATE POLICY "cash_box_movements_update_admin" ON cash_box_movements
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- DELETE: solo admin
DROP POLICY IF EXISTS "cash_box_movements_delete_admin" ON cash_box_movements;
CREATE POLICY "cash_box_movements_delete_admin" ON cash_box_movements
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

SELECT '✅ Políticas de cajas configuradas: solo admin puede operar' AS resultado;
