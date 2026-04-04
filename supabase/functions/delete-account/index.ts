import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // Preflight CORS
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    // ── 1. Leer y validar Authorization header ───────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      console.error("[delete-account] 401 — sin header Authorization");
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!authHeader.startsWith("Bearer ")) {
      console.error("[delete-account] 401 — header mal formado:", authHeader.slice(0, 20));
      return new Response(JSON.stringify({ error: "Header de autorización mal formado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "").trim();
    console.log(`[delete-account] token recibido, longitud: ${token.length}`);

    // ── 2. Cliente admin (service role) ─────────────────────────────────────
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // ── 3. Validar JWT con admin client directamente ─────────────────────────
    // Evita crear un segundo cliente con ANON_KEY (patrón que causa 401 intermitentes)
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);

    if (userError) {
      console.error(`[delete-account] 401 — getUser error: ${userError.message}`);
      return new Response(JSON.stringify({ error: "Token inválido o expirado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!user) {
      console.error("[delete-account] 401 — getUser devolvió null sin error");
      return new Response(JSON.stringify({ error: "Usuario no encontrado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userId = user.id;
    console.log(`[delete-account] Usuario autenticado correctamente: ${userId}`);

    // ── 4. Obtener IDs de productos del usuario ──────────────────────────────
    const { data: products, error: productsError } = await supabaseAdmin
      .from("products")
      .select("id")
      .eq("seller_id", userId);

    if (productsError) {
      console.warn(`[delete-account] Error obteniendo productos: ${productsError.message}`);
    }

    const productIds: string[] = products?.map((p: any) => p.id) ?? [];
    console.log(`[delete-account] Productos encontrados: ${productIds.length}`);

    // ── 5. Borrar Storage: avatars ($userId/...) ─────────────────────────────
    try {
      const { data: avatarFiles, error: listAvatarErr } =
        await supabaseAdmin.storage.from("avatars").list(userId);

      if (listAvatarErr) {
        console.warn(`[delete-account] Error listando avatars: ${listAvatarErr.message}`);
      } else if (avatarFiles && avatarFiles.length > 0) {
        const paths = avatarFiles.map((f: any) => `${userId}/${f.name}`);
        const { error: rmErr } = await supabaseAdmin.storage.from("avatars").remove(paths);
        if (rmErr) {
          console.warn(`[delete-account] Error borrando avatars storage: ${rmErr.message}`);
        } else {
          console.log(`[delete-account] Avatars borrados: ${paths.length}`);
        }
      } else {
        console.log("[delete-account] No hay avatars en storage");
      }
    } catch (e) {
      console.warn(`[delete-account] Excepción avatars storage: ${e}`);
    }

    // ── 6. Borrar Storage: product-images ($userId/...) ──────────────────────
    try {
      const { data: imageFiles, error: listImgErr } =
        await supabaseAdmin.storage.from("product-images").list(userId);

      if (listImgErr) {
        console.warn(`[delete-account] Error listando product-images: ${listImgErr.message}`);
      } else if (imageFiles && imageFiles.length > 0) {
        const paths = imageFiles.map((f: any) => `${userId}/${f.name}`);
        const { error: rmErr } = await supabaseAdmin.storage.from("product-images").remove(paths);
        if (rmErr) {
          console.warn(`[delete-account] Error borrando product-images storage: ${rmErr.message}`);
        } else {
          console.log(`[delete-account] Product-images borradas: ${paths.length}`);
        }
      } else {
        console.log("[delete-account] No hay product-images en storage");
      }
    } catch (e) {
      console.warn(`[delete-account] Excepción product-images storage: ${e}`);
    }

    // ── 7. Borrar product_images en BD ───────────────────────────────────────
    if (productIds.length > 0) {
      const { error: piErr } = await supabaseAdmin
        .from("product_images")
        .delete()
        .in("product_id", productIds);

      if (piErr) {
        console.warn(`[delete-account] Error borrando product_images BD: ${piErr.message}`);
      } else {
        console.log("[delete-account] product_images BD borrados");
      }
    }

    // ── 8. Soft-delete productos ─────────────────────────────────────────────
    const { error: softDeleteErr } = await supabaseAdmin
      .from("products")
      .update({ status: "deleted" })
      .eq("seller_id", userId);

    if (softDeleteErr) {
      console.warn(`[delete-account] Error soft-delete products: ${softDeleteErr.message}`);
    } else {
      console.log("[delete-account] Products marcados como deleted");
    }

    // ── 9. Guardar trazabilidad antes de borrar ──────────────────────────────
    const { data: profileData } = await supabaseAdmin
      .from("profiles")
      .select("display_name, account_type")
      .eq("id", userId)
      .single();

    const { error: auditErr } = await supabaseAdmin
      .from("deleted_accounts")
      .insert({
        user_id: userId,
        email: user.email ?? null,
        display_name: profileData?.display_name ?? null,
        account_type: profileData?.account_type ?? null,
      });

    if (auditErr) {
      console.warn(`[delete-account] Error guardando trazabilidad: ${auditErr.message}`);
    } else {
      console.log("[delete-account] Registro de trazabilidad guardado");
    }

    // ── 10. Borrar perfil ─────────────────────────────────────────────────────
    const { error: profileErr } = await supabaseAdmin
      .from("profiles")
      .delete()
      .eq("id", userId);

    if (profileErr) {
      console.error(`[delete-account] Error borrando profile: ${profileErr.message}`);
    } else {
      console.log("[delete-account] Profile borrado");
    }

    // ── 11. Borrar usuario de Auth ───────────────────────────────────────────
    const { error: authDeleteErr } = await supabaseAdmin.auth.admin.deleteUser(userId);

    if (authDeleteErr) {
      console.error(`[delete-account] Error borrando Auth user: ${authDeleteErr.message}`);
      return new Response(
        JSON.stringify({ error: `No se pudo eliminar el usuario de Auth: ${authDeleteErr.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`[delete-account] Usuario ${userId} eliminado completamente ✓`);
    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (e) {
    console.error(`[delete-account] Error inesperado: ${e}`);
    return new Response(
      JSON.stringify({ error: `Error inesperado: ${String(e)}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
