-- =====================================================
-- FIX: Políticas RLS corregidas
-- Copiá y ejecutá esto en Supabase SQL Editor
-- =====================================================

-- Eliminar políticas problemáticas
DROP POLICY IF EXISTS "Admin full access profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

-- Nueva política simple para profiles
CREATE POLICY "profiles_own_select" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_all" ON profiles
    FOR ALL USING (
        (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
    );

-- mora_config: lectura pública, escritura admin
CREATE POLICY "mora_config_read" ON mora_config FOR SELECT USING (true);

CREATE POLICY "mora_config_all" ON mora_config FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- clients: lectura pública de activos, admin hace todo
CREATE POLICY "clients_read" ON clients FOR SELECT USING (estado = 'activo');

CREATE POLICY "clients_all" ON clients FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- loans: lectura de activos, admin todo
CREATE POLICY "loans_read" ON loans FOR SELECT USING (estado IN ('activo', 'mora', 'a_entregar'));

CREATE POLICY "loans_all" ON loans FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- installments: lectura de activos, admin todo
CREATE POLICY "installments_read" ON installments FOR SELECT USING (
    EXISTS (SELECT 1 FROM loans WHERE loans.id = installments.loan_id AND loans.estado IN ('activo', 'mora', 'a_entregar'))
);

CREATE POLICY "installments_all" ON installments FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- cash_boxes: own read, admin all
CREATE POLICY "cash_boxes_read" ON cash_boxes FOR SELECT USING (cobrador_id = auth.uid());

CREATE POLICY "cash_boxes_all" ON cash_boxes FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- cash_box_movements
CREATE POLICY "movements_read" ON cash_box_movements FOR SELECT USING (
    EXISTS (SELECT 1 FROM cash_boxes WHERE cash_boxes.id = cash_box_movements.box_id AND cash_boxes.cobrador_id = auth.uid())
);

CREATE POLICY "movements_all" ON cash_box_movements FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- payment_attempts
CREATE POLICY "payments_read" ON payment_attempts FOR SELECT USING (cobrador_id = auth.uid());

CREATE POLICY "payments_all" ON payment_attempts FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- delivery_attempts
CREATE POLICY "deliveries_read" ON delivery_attempts FOR SELECT USING (cobrador_id = auth.uid());

CREATE POLICY "deliveries_all" ON delivery_attempts FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- moras
CREATE POLICY "moras_read" ON moras FOR SELECT USING (true);

CREATE POLICY "moras_all" ON moras FOR ALL USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

SELECT 'Políticas RLS corregidas ✅' AS resultado;
