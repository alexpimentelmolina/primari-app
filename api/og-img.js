// ─────────────────────────────────────────────────────────────────────────────
// /api/og-img — Proxy de imagen para OG tags
//
// Problema: Supabase Storage añade "x-robots-tag: none" a todos sus objetos
// públicos. WhatsApp y Telegram respetan ese header y no renderizan la imagen
// aunque la URL sea pública y devuelva 200.
//
// Solución: re-servir la imagen desde nuestro dominio sin ese header, usando
// el endpoint de transformación de Supabase para reducir el tamaño.
//
// Uso: /api/og-img?u=<URL_supabase_encoded>
// ─────────────────────────────────────────────────────────────────────────────

export const config = { runtime: 'edge' };

const ALLOWED_HOST = 'kpqpylsbaopgssxpjrdq.supabase.co';

export default async function handler(request) {
  const { searchParams } = new URL(request.url);
  const raw = searchParams.get('u');

  if (!raw) {
    return new Response('Missing u param', { status: 400 });
  }

  let imgUrl;
  try {
    imgUrl = new URL(decodeURIComponent(raw));
  } catch {
    return new Response('Invalid URL', { status: 400 });
  }

  // Solo permitir URLs de nuestro bucket de Supabase
  if (imgUrl.hostname !== ALLOWED_HOST) {
    return new Response('Forbidden', { status: 403 });
  }

  // Usar el endpoint de render de Supabase para reducir tamaño
  // /object/public/... → /render/image/public/...
  const renderUrl = imgUrl.toString()
    .replace('/storage/v1/object/public/', '/storage/v1/render/image/public/')
    + '?width=800&quality=80&format=origin';

  let upstream;
  try {
    upstream = await fetch(renderUrl);
  } catch {
    return new Response('Upstream error', { status: 502 });
  }

  if (!upstream.ok) {
    return new Response('Image not found', { status: upstream.status });
  }

  const contentType = upstream.headers.get('content-type') || 'image/jpeg';
  const body = await upstream.arrayBuffer();

  return new Response(body, {
    status: 200,
    headers: {
      'Content-Type': contentType,
      'Content-Length': String(body.byteLength),
      'Cache-Control': 'public, max-age=86400, s-maxage=86400',
      'Access-Control-Allow-Origin': '*',
      // x-robots-tag: none de Supabase NO se propaga deliberadamente
    },
  });
}
