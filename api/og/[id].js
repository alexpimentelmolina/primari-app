// ─────────────────────────────────────────────────────────────────────────────
// Vercel Serverless Function: /api/og/:id
// Se ejecuta cuando un bot o usuario accede a /producto/:id
//
// Para bots (WhatsApp, Telegram, Twitter, Facebook, Google):
//   → Devuelve HTML con Open Graph tags del producto específico.
//
// Para usuarios normales (navegador):
//   → Devuelve el mismo HTML, que además carga la app Flutter a través de
//     flutter_bootstrap.js. GoRouter lee la URL y muestra el producto.
//
// La URL canónica del producto es:
//   https://weareprimari.com/producto/<id>
// ─────────────────────────────────────────────────────────────────────────────

const SUPABASE_URL = 'https://kpqpylsbaopgssxpjrdq.supabase.co';
// La anon key es pública (está embebida en la app Flutter).
// Puedes sobrescribirla con la variable de entorno SUPABASE_ANON_KEY en Vercel.
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  'sb_publishable__CpInjR0mmnlsVph8Ukg4w_BZDKxvLJ';

const BASE_URL = 'https://weareprimari.com';
const FALLBACK_IMAGE = `${BASE_URL}/icons/Icon-512.png`;

module.exports = async function handler(req, res) {
  const { id } = req.query;

  // Protección mínima: el ID de Supabase es un UUID, 36 caracteres
  if (!id || id.length > 64 || !/^[a-zA-Z0-9_-]+$/.test(id)) {
    return serveApp(res);
  }

  const headers = {
    apikey: SUPABASE_ANON_KEY,
    Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
  };

  try {
    // Consultas en paralelo: producto e imagen de portada
    const [productRes, imagesRes] = await Promise.all([
      fetch(
        `${SUPABASE_URL}/rest/v1/products` +
          `?id=eq.${id}&status=eq.active` +
          `&select=title,description,cover_image_url,city,price,unit&limit=1`,
        { headers }
      ),
      fetch(
        `${SUPABASE_URL}/rest/v1/product_images` +
          `?product_id=eq.${id}&is_cover=eq.true` +
          `&select=image_url&order=sort_order.asc&limit=1`,
        { headers }
      ),
    ]);

    const [products, images] = await Promise.all([
      productRes.json(),
      imagesRes.json(),
    ]);

    const product = products[0];

    // Producto no encontrado o inactivo: servir la app genérica
    if (!product) return serveApp(res);

    const imageUrl =
      product.cover_image_url ||
      images[0]?.image_url ||
      FALLBACK_IMAGE;

    const productUrl = `${BASE_URL}/producto/${id}`;
    const ogTitle = `${product.title} — Prímari`;
    const rawDesc = product.description || '';
    const ogDescription = rawDesc.length > 200
      ? rawDesc.slice(0, 197) + '…'
      : rawDesc || `${product.title} en ${product.city}. Compra y vende sin intermediarios en Prímari.`;

    const html = buildHtml({
      title: ogTitle,
      description: ogDescription,
      imageUrl,
      productUrl,
      productId: id,
    });

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    // Cache 5 min en CDN, stale-while-revalidate 10 min
    res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');
    return res.status(200).send(html);
  } catch (err) {
    console.error('[og] Error fetching product:', err);
    return serveApp(res);
  }
};

// Sirve la app Flutter sin OG tags de producto (fallback)
function serveApp(res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  return res.status(200).send(buildHtml(null));
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildHtml(product) {
  const title = product
    ? escapeHtml(product.title)
    : 'Prímari | Compra y venta sin intermediarios del sector primario';
  const description = product
    ? escapeHtml(product.description)
    : 'Prímari es la plataforma para comprar y vender productos del sector primario sin intermediarios. Descubre productores locales y venta directa en toda España.';
  const imageUrl = product ? escapeHtml(product.imageUrl) : FALLBACK_IMAGE;
  const canonicalUrl = product
    ? escapeHtml(product.productUrl)
    : BASE_URL + '/';
  const ogType = product ? 'product' : 'website';

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <!--
    Generado por /api/og/[id].js (Vercel Serverless Function)
    Sirve metadatos Open Graph dinámicos por producto.
    El bloque <script> carga la app Flutter para usuarios normales.
  -->
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <title>${title}</title>
  <link rel="canonical" href="${canonicalUrl}">

  <!-- Open Graph -->
  <meta property="og:type" content="${ogType}">
  <meta property="og:url" content="${canonicalUrl}">
  <meta property="og:site_name" content="Prímari">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:image" content="${imageUrl}">
  <meta property="og:image:alt" content="${title}">
  <meta property="og:locale" content="es_ES">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${description}">
  <meta name="twitter:image" content="${imageUrl}">

  <!-- PWA / iOS -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Prímari">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <!--
    flutter_bootstrap.js inicializa la app Flutter.
    Los bots no ejecutan JavaScript, por lo que solo leen los meta tags.
    Los usuarios obtienen la app Flutter completa con GoRouter
    leyendo la URL /producto/:id y mostrando el producto.
  -->
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>`;
}
