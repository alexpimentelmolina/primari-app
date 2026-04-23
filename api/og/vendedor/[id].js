// ─────────────────────────────────────────────────────────────────────────────
// Vercel Serverless Function: /api/og/vendedor/:id
// Se ejecuta cuando un bot accede a /vendedor/:id (vía rewrite en vercel.json)
//
// Para crawlers (Googlebot, Twitterbot, facebookexternalhit, WhatsApp…):
//   → Devuelve HTML con Open Graph tags del perfil del vendedor.
//
// Para usuarios reales:
//   → Devuelve el index.html de Flutter (SPA fallback).
// ─────────────────────────────────────────────────────────────────────────────

const SUPABASE_URL = 'https://kpqpylsbaopgssxpjrdq.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const BASE_URL       = 'https://weareprimari.com';
const IMG_PROXY      = `${BASE_URL}/api/og-img`;
const FALLBACK_IMAGE = `${BASE_URL}/icons/Icon-512.png`;

const CRAWLER_UA_REGEX = /facebookexternalhit|Twitterbot|Telegrambot|LinkedInBot|Slackbot|Discordbot|Applebot|Pinterestbot|Googlebot|Bingbot|bingbot|Slurp|DuckDuckBot|Baiduspider|YandexBot|Sogou|Exabot|ia_archiver|MJ12bot|AhrefsBot|SemrushBot/i;

function isWhatsAppFetcher(ua) {
  return /WhatsApp\/[\d.]/.test(ua) && !/Mozilla\//i.test(ua);
}

function isBotRequest(ua) {
  if (!ua) return false;
  return CRAWLER_UA_REGEX.test(ua) || isWhatsAppFetcher(ua);
}

module.exports = async function handler(req, res) {
  const { id } = req.query;

  if (!id || id.length > 64 || !/^[a-zA-Z0-9_-]+$/.test(id)) {
    return serveApp(res);
  }

  const ua = req.headers['user-agent'] || '';
  if (!isBotRequest(ua)) return serveApp(res);
  if (!SUPABASE_KEY) return serveApp(res);

  const headers = {
    apikey:        SUPABASE_KEY,
    Authorization: `Bearer ${SUPABASE_KEY}`,
  };

  try {
    const profileRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles` +
      `?id=eq.${id}&select=display_name,city,bio,avatar_url,account_type&limit=1`,
      { headers }
    );
    const profiles = await profileRes.json();
    const seller   = Array.isArray(profiles) ? profiles[0] : null;

    if (!seller) {
      console.warn('[og/vendedor] seller not found:', id);
      return serveApp(res);
    }

    const pageUrl  = `${BASE_URL}/vendedor/${id}`;
    const name     = seller.display_name || 'Productor';
    const ogTitle  = `${name} — Prímari`;
    const rawBio   = seller.bio || '';
    const location = seller.city ? `en ${seller.city}` : 'en Prímari';
    const ogDesc   = rawBio.length > 200
      ? rawBio.slice(0, 197) + '…'
      : rawBio || `Descubre los productos de ${name} ${location}. Compra directa sin intermediarios.`;

    // Avatar a través del proxy para eliminar x-robots-tag: none de Supabase
    const imageUrl = seller.avatar_url && seller.avatar_url.startsWith('http')
      ? `${IMG_PROXY}?u=${encodeURIComponent(seller.avatar_url)}`
      : FALLBACK_IMAGE;

    console.log(`[og/vendedor] id=${id} name=${name} image=${imageUrl}`);

    const html = buildOgHtml({ title: ogTitle, description: ogDesc, imageUrl, pageUrl });

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, s-maxage=60, stale-while-revalidate=3600');
    return res.status(200).send(html);
  } catch (err) {
    console.error('[og/vendedor] Error:', err);
    return serveApp(res);
  }
};

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

function buildOgHtml({ title, description, imageUrl, pageUrl }) {
  const t   = escapeHtml(title);
  const d   = escapeHtml(description);
  const img = escapeHtml(imageUrl);
  const url = escapeHtml(pageUrl);

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>${t}</title>
  <link rel="canonical" href="${url}">

  <!-- Open Graph -->
  <meta property="og:type" content="profile">
  <meta property="og:url" content="${url}">
  <meta property="og:site_name" content="Prímari">
  <meta property="og:title" content="${t}">
  <meta property="og:description" content="${d}">
  <meta property="og:image" content="${img}">
  <meta property="og:image:secure_url" content="${img}">
  <meta property="og:image:alt" content="${t}">
  <meta property="og:locale" content="es_ES">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="${t}">
  <meta name="twitter:description" content="${d}">
  <meta name="twitter:image" content="${img}">
</head>
<body>
  <h1>${t}</h1>
  <p>${d}</p>
  <img src="${img}" alt="${t}">
  <a href="${url}">Ver perfil en Prímari</a>
</body>
</html>`;
}

function buildAppHtml() {
  return `<!DOCTYPE html>
<html lang="es">
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Prímari | Compra y venta sin intermediarios del sector primario</title>
  <meta property="og:type" content="website">
  <meta property="og:url" content="${BASE_URL}/">
  <meta property="og:site_name" content="Prímari">
  <meta property="og:title" content="Prímari | Compra y venta sin intermediarios del sector primario">
  <meta property="og:description" content="Prímari es la plataforma para comprar y vender productos del sector primario sin intermediarios.">
  <meta property="og:image" content="${FALLBACK_IMAGE}">
  <link rel="icon" type="image/png" href="/favicon.png">
  <link rel="manifest" href="/manifest.json">
</head>
<body>
  <script src="/flutter_bootstrap.js" async></script>
</body>
</html>`;
}
