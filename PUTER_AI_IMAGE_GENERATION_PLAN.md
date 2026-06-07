# Implementation Plan: Puter.js AI Image Generation Integration

This document outlines the strategic integration of **Puter.js** into Desby OS to provide free, unlimited, and serverless AI image generation for fashion designers and clients.

## 1. Executive Summary & Audit

### Audit Findings:
- **Zero-Cost Scaling**: Puter.js uses a "User-Pays" model. Each user signs into their own Puter account (or uses the free tier), meaning Desby OS pays $0 for high-end DALL-E 3 or Flux generation.
- **Platform Constraint**: Puter.js is a browser-first JavaScript library. 
    - **Web**: Native support via JS Interop.
    - **Native (Mobile/Desktop)**: Requires a hidden `WebView` proxy or a backend bridge.
- **Business Use Case**: Ideal for the **Design Gallery** (concept generation) and **Booking Flow** (visualizing architectural requirements).

---

## 2. Phase 1: Infrastructure & Core Service

### 2.1. Web Asset Injection
Add the Puter.js script to `web/index.html` to enable the global `puter` object.

```html
<script src="https://js.puter.com/v2/"></script>
```

### 2.2. Abstract AI Service Layer
Create a platform-agnostic service in `lib/core/services/ai_image_service.dart`.

```dart
abstract class AiImageService {
  Future<String?> generateImage(String prompt, {String model = 'dall-e-3'});
}
```

### 2.3. Web Implementation (JS Interop)
Create `lib/core/services/ai_image_service_web.dart`.
- Use `dart:js_interop` to call `puter.ai.txt2img()`.
- Extract the `src` attribute from the returned `HTMLImageElement`.

---

## 3. Phase 2: Design Gallery Integration

### 3.1. "AI Concept Generator" Button
Add a persistent "AI Concept" button to `lib/features/designs/presentation/pages/design_gallery_page.dart`.

### 3.2. Prompt Construction Engine
Automatically enrich the user's fashion prompt with Desby-optimized keywords:
- *Input*: "Agbada with gold embroidery"
- *Optimized*: "High-definition professional fashion photography, Agbada with gold embroidery, African luxury fashion, detailed silk texture, 8k resolution."

---

## 4. Phase 3: Booking Flow Visualization

### 4.1. Visual Architecture Verification
In `lib/features/clients/presentation/pages/unified_add_client_page.dart`:
- After the user selects "Garment Type," "Colors," and "Fabrics," trigger a background AI generation.
- Show the generated image as a "Mood Board" reference during the review step.

---

## 5. Technical Challenges & Mitigations

| Challenge | Mitigation |
|-----------|------------|
| **Cross-Platform** | Initially rollout to Web. Implement a `WebView` bridge for Mobile in Phase 2. |
| **Puter Auth** | Puter may prompt the user to sign in if they exceed the free quota. Desby will handle this via a standard browser redirect. |
| **Image Persistence** | Generated images will be uploaded to the existing **Firebase Storage** architecture once confirmed by the user. |

## 6. Model Selection Strategy

Desby OS will support a "Quality Selector" for Pro users:
- **Standard**: `gpt-image-1` (Fast, low cost)
- **Pro (Fashion-First)**: `black-forest-labs/flux-schnell` (High photographic detail)
- **Artistic**: `dall-e-3` (Creative and symbolic)

---

## 7. Immediate Next Actions

1.  [ ] Inject `<script src="https://js.puter.com/v2/"></script>` into `web/index.html`.
2.  [ ] Create the `AiImageService` and `web` implementation.
3.  [ ] Prototype the UI in the **Design Gallery**.
