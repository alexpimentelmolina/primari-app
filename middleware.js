// ─────────────────────────────────────────────────────────────────────────────
// Vercel Edge Middleware — OG tags para bots en /producto/:id
//
// Corre en el Vercel Edge, ANTES de:
//   - El redirect 307 weareprimari.com → www.weareprimari.com
//   - Los rewrites de vercel.json
//   - El Edge cache de archivos estáticos
//
// Para bots (Googlebot, facebookexternalhit, Twitterbot, WhatsApp fetcher…):
//   → Consulta Supabase y devuelve HTML con og:image del producto.
//
// Para usuarios reales:
//   → return undefined → routing normal → Flutter app.
// ─────────────────────────────────────────────────────────────────────────────

export const config = {
  matcher: '/producto/:id',
};

const SUPABASE_URL = 'https://kpqpylsbaopgssxpjrdq.supabase.co';
const BASE_URL     = 'https://www.weareprimari.com';
const IMG_PROXY    = `${BASE_URL}/api/og-img`;
const FALLBACK_IMAGE = `${BASE_URL}/icons/Icon-512.png`;

const CRAWLER_UA_REGEX =
  /facebookexternalhit|Twitterbot|Telegrambot|LinkedInBot|Slackbot|Discordbot|Applebot|Pinterestbot|Googlebot|Bingbot|bingbot|Slurp|DuckDuckBot|Baiduspider|YandexBot|Sogou|Exabot|ia_archiver|MJ12bot|AhrefsBot|SemrushBot/i;

function isWhatsAppFetcher(ua) {
  // UA tipo "WhatsApp/2.x A" sin prefijo "Mozilla/" = fetcher backend (bot)
  // UA tipo "Mozilla/5.0 … WhatsApp/24.x" = in-app browser (usuario real)
  return /WhatsApp\/[\d.]/.test(ua) && !/Mozilla\//i.test(ua);
}

function isBotRequest(ua) {
  if (!ua) return false;
  return CRAWLER_UA_REGEX.test(ua) || isWhatsAppFetcher(ua);
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildOgHtml({ title, description, imageUrl, productUrl }) {
  const t   = escapeHtml(title);
  const d   = escapeHtml(description);
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
  <meta property="og:image:secure_url" content="${img}">
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

export default async function middleware(request) {
  const ua = request.headers.get('user-agent') || '';
  if (!isBotRequest(ua)) return; // usuario real → routing normal

  const url = new URL(request.url);
  const id  = url.pathname.split('/')[2];
  if (!id || id.length > 64 || !/^[a-zA-Z0-9_-]+$/.test(id)) return;

  const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
  if (!SUPABASE_KEY) return; // sin clave → routing normal (OG genérico)

  try {
    const headers = {
      apikey:        SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
    };

    const [productRes, imagesRes] = await Promise.all([
      fetch(
        `${SUPABASE_URL}/rest/v1/products` +
        `?id=eq.${id}&status=eq.active` +
        `&select=title,description,cover_image_url,city&limit=1`,
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

    const product = Array.isArray(products) ? products[0] : null;
    if (!product) return; // producto no encontrado → routing normal

    const galleryUrl   = Array.isArray(images) ? images[0]?.image_url : null;
    const candidateUrl = product.cover_image_url || galleryUrl;
    // Supabase Storage añade "x-robots-tag: none" en todas sus respuestas.
    // WhatsApp/Telegram respetan ese header y no renderizan la imagen.
    // Solución: re-servir a través de nuestro proxy /api/og-img que omite ese header.
    const imageUrl     =
      candidateUrl && candidateUrl.startsWith('http')
        ? `${IMG_PROXY}?u=${encodeURIComponent(candidateUrl)}`
        : FALLBACK_IMAGE;

    const productUrl = `${BASE_URL}/producto/${id}`;
    const ogTitle    = `${product.title} — Prímari`;
    const rawDesc    = product.description || '';
    const ogDesc     =
      rawDesc.length > 200
        ? rawDesc.slice(0, 197) + '…'
        : rawDesc ||
          `${product.title} en ${product.city}. Compra y vende sin intermediarios en Prímari.`;

    const html = buildOgHtml({
      title:       ogTitle,
      description: ogDesc,
      imageUrl,
      productUrl,
    });

    return new Response(html, {
      headers: {
        'Content-Type':  'text/html; charset=utf-8',
        'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=3600',
      },
    });
  } catch (_) {
    return; // error → routing normal
  }
}
