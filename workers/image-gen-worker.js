// Cloudflare Worker — Desby Image Generation
// Model: @cf/black-forest-labs/flux-2-klein-9b
// Accepts POST with form data, returns JPEG image

export default {
  async fetch(request, env) {
    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }

    try {
      let prompt;
      let width = 1024;
      let height = 1536;
      let guidance = 8.0;

      const contentType = request.headers.get('content-type') || '';

      if (contentType.includes('multipart/form-data')) {
        // Multipart form data (primary path)
        const formData = await request.formData();
        prompt = formData.get('prompt');
        const w = formData.get('width');
        const h = formData.get('height');
        const g = formData.get('guidance');
        if (w) width = Math.min(1920, Math.max(256, parseInt(w) || 1024));
        if (h) height = Math.min(1920, Math.max(256, parseInt(h) || 1536));
        if (g) guidance = Math.min(20, Math.max(1, parseFloat(g) || 8.0));
      } else if (contentType.includes('application/json')) {
        // JSON fallback
        const body = await request.json();
        prompt = body.prompt;
        if (body.width) width = Math.min(1920, Math.max(256, body.width));
        if (body.height) height = Math.min(1920, Math.max(256, body.height));
        if (body.guidance) guidance = Math.min(20, Math.max(1, body.guidance));
      } else {
        // URL query params fallback (backward compat)
        const url = new URL(request.url);
        prompt = url.searchParams.get('prompt');
      }

      if (!prompt || prompt.trim().length === 0) {
        return new Response(JSON.stringify({ error: 'Prompt is required' }), {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        });
      }

      console.log(`[IMAGE-GEN] Prompt: ${prompt.substring(0, 100)}...`);
      console.log(`[IMAGE-GEN] Params: ${width}x${height}, guidance: ${guidance}`);

      // Build multipart form for FLUX.2 klein-9b
      const form = new FormData();
      form.append('prompt', prompt);
      form.append('width', String(width));
      form.append('height', String(height));
      form.append('guidance', String(guidance));

      const formResponse = new Response(form);
      const formStream = formResponse.body;
      const formContentType = formResponse.headers.get('content-type');

      const resp = await env.AI.run('@cf/black-forest-labs/flux-2-klein-9b', {
        multipart: {
          body: formStream,
          contentType: formContentType,
        },
      });

      // resp is { image: "base64..." }
      if (!resp || !resp.image) {
        console.error('[IMAGE-GEN] No image returned from model');
        return new Response(JSON.stringify({ error: 'Image generation failed' }), {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        });
      }

      // Convert base64 to binary
      const imageBytes = Uint8Array.from(atob(resp.image), c => c.charCodeAt(0));

      console.log(`[IMAGE-GEN] Success: ${imageBytes.length} bytes`);

      return new Response(imageBytes, {
        status: 200,
        headers: {
          'Content-Type': 'image/jpeg',
          'Cache-Control': 'public, max-age=3600',
          'Access-Control-Allow-Origin': '*',
        },
      });
    } catch (err) {
      console.error('[IMAGE-GEN] Error:', err.message);
      return new Response(JSON.stringify({ error: err.message }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }
  },
};
