-- Políticas RLS para clients - Solo admin puede modificar, todos pueden leer activos

-- Eliminar políticas existentes
DROP POLICY IF EXISTS "clients_insert" ON clients;
DROP POLICY IF EXISTS "clients_select" ON clients;
DROP POLICY IF EXISTS "clients_update" ON clients;
DROP POLICY IF EXISTS "clients_delete" ON clients;

-- Solo admin puede hacer INSERT
CREATE POLICY "clients_insert_admin" ON clients
    FOR INSERT WITH CHECK (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Todos pueden leer clientes activos
CREATE POLICY "clients_select_all" ON clients
    FOR SELECT USING (estado = 'activo');

-- Solo admin puede actualizar
CREATE POLICY "clients_update_admin" ON clients
    FOR UPDATE USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Solo admin puede eliminar
CREATE POLICY "clients_delete_admin" ON clients
    FOR DELETE USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

SELECT 'Políticas de clients actualizadas - Solo admin puede modificar ✅' AS resultado;
