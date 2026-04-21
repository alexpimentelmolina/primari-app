// ─────────────────────────────────────────────────────────────────────────────
// Vercel Serverless Function: /api/og/:id
// Se ejecuta cuando un bot o usuario accede a /producto/:id
//
// Para crawlers reales (Googlebot, Twitterbot, facebookexternalhit, etc.):
//   → Devuelve HTML con Open Graph tags del producto específico.
//
// Para usuarios reales (navegador, in-app browsers):
//   → Devuelve el index.html de Flutter para que la SPA cargue
//     y GoRouter muestre el producto.
//
// La URL canónica del producto es:
//   https://weareprimari.com/producto/<id>
// ─────────────────────────────────────────────────────────────────────────────

const SUPABASE_URL = 'https://kpqpylsbaopgssxpjrdq.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const BASE_URL = 'https://weareprimari.com';
const FALLBACK_IMAGE = `${BASE_URL}/icons/Icon-512.png`;

// Crawlers puros de redes sociales y motores de búsqueda.
// NOTA: NO incluye "WhatsApp" aquí — ver lógica separada abajo.
// Estos UAs son de bots dedicados que NO llevan prefijo "Mozilla/5.0".
const CRAWLER_UA_REGEX = /facebookexternalhit|Twitterbot|Telegrambot|LinkedInBot|Slackbot|Discordbot|Applebot|Pinterestbot|Googlebot|Bingbot|bingbot|Slurp|DuckDuckBot|Baiduspider|YandexBot|Sogou|Exabot|ia_archiver|MJ12bot|AhrefsBot|SemrushBot/i;

// Devuelve true solo para el fetcher de preview de WhatsApp (backend),
// que tiene UA tipo "WhatsApp/2.x A" sin prefijo de navegador.
// El in-app browser de WhatsApp lleva "Mozilla/5.0" + "WhatsApp/24.x":
// ese es un usuario real que debe recibir la app Flutter, no OG HTML.
function isWhatsAppFetcher(ua) {
  return /WhatsApp\/[\d.]/.test(ua) && !/Mozilla\//i.test(ua);
}

// Determina si la petición viene de un crawler/bot que necesita OG tags.
// Regla: UA vacío → tratar como usuario (safe default → Flutter app).
function isBotRequest(ua) {
  if (!ua) return false;
  return CRAWLER_UA_REGEX.test(ua) || isWhatsAppFetcher(ua);
}

module.exports = async function handler(req, res) {
  const { id } = req.query;

  // Protección mínima: el ID de Supabase es un UUID, 36 caracteres
  if (!id || id.length > 64 || !/^[a-zA-Z0-9_-]+$/.test(id)) {
    return serveApp(res);
  }

  const ua = req.headers['user-agent'] || '';
  const isBot = isBotRequest(ua);

  // Si no es bot y no tenemos service role key, servir la app directamente
  if (!isBot) {
    return serveApp(res);
  }

  // Si no hay key configurada, servir OG genérico
  if (!SUPABASE_KEY) {
    console.warn('[og] SUPABASE_SERVICE_ROLE_KEY not set — serving generic OG');
    return serveApp(res);
  }

  const headers = {
    apikey: SUPABASE_KEY,
    Authorization: `Bearer ${SUPABASE_KEY}`,
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
          `?product_id=eq.${id}` +
          `&select=image_url&order=sort_order.asc&limit=1`,
        { headers }
      ),
    ]);

    const [products, images] = await Promise.all([
      productRes.json(),
      imagesRes.json(),
    ]);

    const product = products[0];

    // Producto no encontrado o inactivo: servir OG genérico
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

    const html = buildOgHtml({
      title: ogTitle,
      description: ogDescription,
      imageUrl,
      productUrl,
    });

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, s-maxage=300, stale-while-revalidate=86400');
    return res.status(200).send(html);
  } catch (err) {
    console.error('[og] Error fetching product:', err);
    return serveApp(res);
  }
};

// Sirve el index.html de Flutter (SPA fallback para usuarios normales)
function serveApp(res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  return res.status(200).send(buildAppHtml());
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// HTML con OG tags reales del producto (para bots)
function buildOgHtml({ title, description, imageUrl, productUrl }) {
  const t = escapeHtml(title);
  const d = escapeHtml(description);
  const img = escapeHtml(imageUrl);
  const url = escapeHtml(productUrl);

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>${t}</title>
  <link rel="canonical" href="${url}">

  <!-- Open Graph -->
  <meta property="og:type" content="product">
  <meta property="og:url" content="${url}">
  <meta property="og:site_name" content="Prímari">
  <meta property="og:title" content="${t}">
  <meta property="og:description" content="${d}">
  <meta property="og:image" content="${img}">
  <meta property="og:image:alt" content="${t}">
  <meta property="og:locale" content="es_ES">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${t}">
  <meta name="twitter:description" content="${d}">
  <meta name="twitter:image" content="${img}">
</head>
<body>
  <h1>${t}</h1>
  <p>${d}</p>
  <img src="${img}" alt="${t}">
  <a href="${url}">Ver en Prímari</a>
</body>
</html>`;
}

// HTML que carga la app Flutter (para usuarios normales)
function buildAppHtml() {
  return `<!DOCTYPE html>
<html lang="es">
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <title>Prímari | Compra y venta sin intermediarios del sector primario</title>

  <!-- Open Graph genérico -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="${BASE_URL}/">
  <meta property="og:site_name" content="Prímari">
  <meta property="og:title" content="Prímari | Compra y venta sin intermediarios del sector primario">
  <meta property="og:description" content="Prímari es la plataforma para comprar y vender productos del sector primario sin intermediarios. Descubre productores locales y venta directa en toda España.">
  <meta property="og:image" content="${FALLBACK_IMAGE}">
  <meta property="og:locale" content="es_ES">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Prímari | Compra y venta sin intermediarios del sector primario">
  <meta name="twitter:description" content="Prímari es la plataforma para comprar y vender productos del sector primario sin intermediarios.">
  <meta name="twitter:image" content="${FALLBACK_IMAGE}">

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
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>`;
}
