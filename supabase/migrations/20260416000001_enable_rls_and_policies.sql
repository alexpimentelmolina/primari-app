-- ═══════════════════════════════════════════════════════════════════════════════
-- MIGRACIÓN: Activar RLS y definir políticas de mínimo privilegio
-- Proyecto: PRÍMARI  ·  kpqpylsbaopgssxpjrdq  ·  weareprimari.com
-- Fecha: 2026-04-16
-- Motivo: aviso crítico Supabase — tablas sin RLS en esquema public
--
-- PRINCIPIO APLICADO: mínimo privilegio.
-- Cada tabla recibe exactamente los permisos que la app necesita.
-- Ninguna tabla permite escritura anónima. Ningún usuario puede
-- leer ni modificar datos de otro usuario, salvo donde sea público
-- por diseño (productos activos, perfiles de vendedores, valoraciones).
--
-- HOW TO RUN: pegar este archivo completo en el SQL Editor de Supabase
-- (Dashboard → SQL Editor → New query) y ejecutar.
-- ═══════════════════════════════════════════════════════════════════════════════


-- ─── PASO 1: ACTIVAR RLS EN TODAS LAS TABLAS PUBLIC ─────────────────────────
-- Si RLS ya estaba activado en alguna tabla, estas sentencias son no-ops seguros.

ALTER TABLE public.products               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_reports        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seasonal_widget_config ENABLE ROW LEVEL SECURITY;


-- ─── PASO 2: LIMPIAR POLÍTICAS ANTERIORES (idempotente) ─────────────────────
-- DROP IF EXISTS garantiza que la migración se puede ejecutar más de una vez
-- sin errores.

-- products
DROP POLICY IF EXISTS "products_public_select"  ON public.products;
DROP POLICY IF EXISTS "products_owner_select"   ON public.products;
DROP POLICY IF EXISTS "products_owner_insert"   ON public.products;
DROP POLICY IF EXISTS "products_owner_update"   ON public.products;

-- product_images
DROP POLICY IF EXISTS "product_images_public_select"  ON public.product_images;
DROP POLICY IF EXISTS "product_images_owner_insert"   ON public.product_images;
DROP POLICY IF EXISTS "product_images_owner_delete"   ON public.product_images;

-- profiles
DROP POLICY IF EXISTS "profiles_public_select"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_owner_insert"   ON public.profiles;
DROP POLICY IF EXISTS "profiles_owner_update"   ON public.profiles;

-- product_reports
DROP POLICY IF EXISTS "product_reports_auth_insert"  ON public.product_reports;
DROP POLICY IF EXISTS "product_reports_auth_update"  ON public.product_reports;

-- reviews
DROP POLICY IF EXISTS "reviews_public_select"   ON public.reviews;
DROP POLICY IF EXISTS "reviews_auth_insert"     ON public.reviews;
DROP POLICY IF EXISTS "reviews_owner_update"    ON public.reviews;

-- favorites
DROP POLICY IF EXISTS "favorites_owner_select"  ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_insert"  ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_delete"  ON public.favorites;

-- seasonal_widget_config
DROP POLICY IF EXISTS "seasonal_config_public_select"  ON public.seasonal_widget_config;

-- storage (se borran con el nombre exacto que se creará abajo)
DROP POLICY IF EXISTS "avatars_public_read"              ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_insert"             ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_update"             ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_delete"             ON storage.objects;
DROP POLICY IF EXISTS "product_images_bucket_public_read"   ON storage.objects;
DROP POLICY IF EXISTS "product_images_bucket_owner_insert"  ON storage.objects;
DROP POLICY IF EXISTS "product_images_bucket_owner_delete"  ON storage.objects;


-- ════════════════════════════════════════════════════════════════════════════════
-- TABLA: products
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Lectura pública SOLO de productos activos (status = 'active').
-- Usada por: getActiveProducts, searchProducts, _searchBasic,
--            getSellerActiveProducts, getProductDetail (usuarios no propietarios)
--
-- El vendedor propietario puede leer todos sus productos sin importar el status.
-- Usada por: getMyProducts (status != 'deleted'), getMyActiveProducts,
--            getProductDetail (propio producto aunque esté inactivo)
--
-- Dos políticas SELECT se evalúan con lógica OR por Supabase:
--   acceso si (status = 'active') OR (seller_id = auth.uid())
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "products_public_select" ON public.products
  FOR SELECT
  USING (status = 'active');

CREATE POLICY "products_owner_select" ON public.products
  FOR SELECT
  USING (seller_id = auth.uid());

-- Solo el usuario autenticado puede crear un producto y
-- únicamente con su propio seller_id. Previene suplantación.
CREATE POLICY "products_owner_insert" ON public.products
  FOR INSERT
  WITH CHECK (seller_id = auth.uid());

-- Solo el propietario puede actualizar su producto.
-- WITH CHECK adicional garantiza que seller_id no puede cambiarse
-- a otro usuario.
-- Cubre: updateProduct, updateStatus (soft delete), geocodeAndUpdateCoords
CREATE POLICY "products_owner_update" ON public.products
  FOR UPDATE
  USING    (seller_id = auth.uid())
  WITH CHECK (seller_id = auth.uid());

-- No hay política DELETE: la app usa soft delete (status = 'deleted')
-- por lo que el DELETE duro está bloqueado para todos via cliente.


-- ════════════════════════════════════════════════════════════════════════════════
-- TABLA: product_images
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Las imágenes son URLs públicas accesibles desde el storage.
-- SELECT abierto es correcto: la URL ya es pública una vez subida.
-- Solo el propietario del producto asociado puede insertar o borrar imágenes.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "product_images_public_select" ON public.product_images
  FOR SELECT
  USING (true);

-- replaceImages() → INSERT batch de imágenes de un producto propio.
CREATE POLICY "product_images_owner_insert" ON public.product_images
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products
      WHERE id        = product_id
        AND seller_id = auth.uid()
    )
  );

-- replaceImages() → DELETE previo de todas las imágenes del producto.
CREATE POLICY "product_images_owner_delete" ON public.product_images
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.products
      WHERE id        = product_id
        AND seller_id = auth.uid()
    )
  );


-- ════════════════════════════════════════════════════════════════════════════════
-- TABLA: profiles
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Los perfiles de vendedores son públicos por diseño (la app los muestra en
-- la ficha de vendedor y en el detalle de producto).
-- Usada por: getSellerProfile, getProductDetail (join a profiles)
--
-- Cada usuario puede crear y actualizar solo su propio perfil (id = auth.uid()).
-- Usada por: upsertProfile (INSERT + UPDATE), updateAvatarUrl
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "profiles_public_select" ON public.profiles
  FOR SELECT
  USING (true);

CREATE POLICY "profiles_owner_insert" ON public.profiles
  FOR INSERT
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_owner_update" ON public.profiles
  FOR UPDATE
  USING    (id = auth.uid())
  WITH CHECK (id = auth.uid());


-- ════════════════════════════════════════════════════════════════════════════════
-- TABLA: product_reports
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Tabla interna. No hay ninguna lectura de reportes en el cliente Flutter.
-- El panel de administración lee los reportes con la service_role key,
-- que siempre bypassa RLS. Por tanto: SIN política SELECT para anon ni auth.
--
-- Solo usuarios autenticados pueden insertar o actualizar sus propios reportes.
-- La app usa UPSERT con ON CONFLICT (reporter_id, product_id), que en
-- PostgreSQL ejecuta INSERT + UPDATE si hay conflicto. Se necesitan ambas.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "product_reports_auth_insert" ON public.product_reports
  FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

-- Cubre la rama UPDATE del UPSERT. Impide además que se cambie reporter_id.
CREATE POLICY "product_reports_auth_update" ON public.product_reports
  FOR UPDATE
  USING    (reporter_id = auth.uid())
  WITH CHECK (reporter_id = auth.uid());


-- ════════════════════════════════════════════════════════════════════════════════
-- TABLA: reviews
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Las valoraciones son públicas: se muestran en el perfil del vendedor.
-- Usada por: getSellerReviews (con JOIN a profiles), getRatingSummary
--
-- Un usuario autenticado puede crear su propia valoración (reviewer_id = uid).
-- Solo puede actualizar su propia valoración existente.
-- Usada por: submitReview (comprueba si existe, luego INSERT o UPDATE)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "reviews_public_select" ON public.reviews
  FOR SELECT
  USING (true);

CREATE POLICY "reviews_auth_insert" ON public.reviews
  FOR INSERT
  WITH CHECK (reviewer_id = auth.uid());

-- submitReview() hace UPDATE de rating y comment de la propia valoración.
CREATE POLICY "reviews_owner_update" ON public.reviews
  FOR UPDATE
  USING    (reviewer_id = auth.uid())
  WITH CHECK (reviewer_id = auth.uid());


-- ════════════════════════════════════════════════════════════════════════════════
-- TABLA: favorites
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Completamente privado. Cada usuario ve, crea y borra solo sus propios favoritos.
-- No existe ningún acceso anónimo ni cruzado entre usuarios.
-- Usada por: getFavoriteIds, getFavoriteProducts, add, remove
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "favorites_owner_select" ON public.favorites
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "favorites_owner_insert" ON public.favorites
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "favorites_owner_delete" ON public.favorites
  FOR DELETE
  USING (user_id = auth.uid());


-- ════════════════════════════════════════════════════════════════════════════════
-- TABLA: seasonal_widget_config
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Configuración del banner estacional en la home. Solo lectura pública.
-- Ningún cliente puede crear, modificar ni borrar filas de esta tabla.
-- Las actualizaciones se hacen directamente desde el panel de Supabase.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "seasonal_config_public_select" ON public.seasonal_widget_config
  FOR SELECT
  USING (true);


-- ════════════════════════════════════════════════════════════════════════════════
-- STORAGE: bucket "avatars"
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Los avatares son URLs públicas que se muestran en perfiles y listados.
-- Upload/update/delete restringido a la carpeta propia del usuario: {uid}/...
-- La función storage.foldername(name)[1] extrae el primer segmento del path.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_owner_insert" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- profile_service.dart usa upsert=true → necesita UPDATE sobre el mismo path.
CREATE POLICY "avatars_owner_update" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars_owner_delete" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );


-- ════════════════════════════════════════════════════════════════════════════════
-- STORAGE: bucket "product-images"
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Las imágenes de productos son URLs públicas embebidas en los listados.
-- Upload restringido a la carpeta propia del usuario: {uid}/...
-- image_service.dart usa upsert=false, así que no se necesita UPDATE policy.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY "product_images_bucket_public_read" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'product-images');

CREATE POLICY "product_images_bucket_owner_insert" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- image_service.dart no tiene función de borrado explícito de storage,
-- pero se deja la política para un uso futuro seguro.
CREATE POLICY "product_images_bucket_owner_delete" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'product-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );


-- ═══════════════════════════════════════════════════════════════════════════════
-- FIN DE MIGRACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- RESUMEN DE POLÍTICAS APLICADAS:
--
--   products              SELECT (activos, público) + SELECT (propios, auth)
--                         INSERT (auth, seller_id = uid)
--                         UPDATE (auth, seller_id = uid, no cambio de seller)
--                         DELETE → BLOQUEADO (la app usa soft delete)
--
--   product_images        SELECT (público)
--                         INSERT (auth, verificando propiedad del producto)
--                         DELETE (auth, verificando propiedad del producto)
--
--   profiles              SELECT (público — necesario para ficha de vendedor)
--                         INSERT (auth, id = uid)
--                         UPDATE (auth, id = uid)
--
--   product_reports       INSERT (auth, reporter_id = uid)
--                         UPDATE (auth, reporter_id = uid — cubre upsert)
--                         SELECT → BLOQUEADO (solo admin vía service_role)
--
--   reviews               SELECT (público — valoraciones visibles en perfil)
--                         INSERT (auth, reviewer_id = uid)
--                         UPDATE (auth, reviewer_id = uid)
--
--   favorites             SELECT / INSERT / DELETE (auth, user_id = uid)
--
--   seasonal_widget_config SELECT (público — solo lectura)
--                          INSERT / UPDATE / DELETE → BLOQUEADOS
--
--   storage: avatars       SELECT (público) | INSERT/UPDATE/DELETE (auth, propia carpeta)
--   storage: product-images SELECT (público) | INSERT/DELETE (auth, propia carpeta)
-- ═══════════════════════════════════════════════════════════════════════════════
