-- Actualizar políticas de loans para permitir updates por authenticated users
-- (Para desarrollo - después restrictivo)

DROP POLICY IF EXISTS "loans_insert_admin" ON loans;
DROP POLICY IF EXISTS "loans_update_admin" ON loans;
DROP POLICY IF EXISTS "loans_delete_admin" ON loans;

-- Cualquier usuario autenticado puede hacer INSERT
CREATE POLICY "loans_insert" ON loans
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Cualquier usuario autenticado puede hacer UPDATE
CREATE POLICY "loans_update" ON loans
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Solo admin puede DELETE
CREATE POLICY "loans_delete_admin" ON loans
    FOR DELETE USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

SELECT 'Políticas de loans actualizadas ✅' AS resultado;
