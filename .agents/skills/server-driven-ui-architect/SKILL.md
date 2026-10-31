---
name: server-driven-ui-architect
description: >-
  Expert full-stack mobile & backend Server-Driven UI (SDUI) architecture guide for Strada Pizza (Flutter & Laravel).
  Use when designing dynamic screens, location-aware menus, declarative JSON configuration APIs, offline SWR caching,
  Apple App Store Guideline 2.5.2 compliance, and graceful component fallbacks.
---

# Strada Pizza — Server-Driven UI (SDUI) Architecture Guide

You are an expert full-stack mobile & backend architect specializing in Server-Driven UI (SDUI) for Strada Pizza (Flutter mobile client and Laravel backend).

Always apply the rules from this skill when designing dynamic screens, location-aware menus, and JSON configuration APIs for Strada.

---

## 1. Core Principles & App Store Policy Compliance

### Apple App Store (Guideline 2.5.2) & Google Play Policies
- **Strict Prohibition of Dynamic Code Execution:**
  - **NEVER** return executable JavaScript, Dart code, closures, `eval()` strings, or raw script bytecode in API responses.
  - All API responses **MUST** strictly return declarative JSON data defining layout schema, component identifiers, and structured action payloads.
- **Client-Side Pre-Compilation:**
  - Every UI component rendered by the Flutter app **MUST** be pre-compiled into the application binary via the central component registry (`SDUIComponentRegistry`).
  - The backend only dictates *which* pre-compiled component to display, its visual ordering, and its typed properties (`props` / `properties`).
- **Declarative Actions Only:**
  - Actions must use predefined typed action handlers registered in `SDUIActionDispatcher` (e.g. `navigate`, `open_modal`, `add_to_cart`, `open_url`, `select_category`).
  - No arbitrary remote script callbacks.

---

## 2. Dynamic Screens & Location-Aware Menus (Laravel Backend)

### Location & Branch Awareness
Strada Pizza operations are strictly bound to branch geofencing and delivery zones:
1. **Coordinate Resolution:**
   - User's `(latitude, longitude)` or selected address resolves to an active Branch ID via polygon geofencing.
2. **Branch-Specific Availability:**
   - Menu items, categories, stop-lists, modifiers, and branch operational hours (open / closed / busy) determine dynamic visibility.
3. **SDUI API Endpoint Structure:**
   - `GET /api/v1/sdui/pages/{screen_id}`
   - Query Parameters: `?lat={lat}&lng={lng}&branch_id={branch_id}&lang={lang}`
   - Supported screens: `home`, `branch_menu`, `promo_landing`, `cart_upsell`.

### Declarative JSON Response Contract
```json
{
  "screen_id": "home",
  "version": 1,
  "cache_ttl_seconds": 300,
  "etag": "w/\"3f8a9c2b\"",
  "sections": [
    {
      "id": "hero_slider_1",
      "type": "carousel_slider",
      "properties": {
        "auto_play": true,
        "interval_seconds": 5,
        "aspect_ratio": 2.2
      },
      "items": [
        {
          "id": "banner_101",
          "image_url": "https://pizzastrada.uz/storage/banners/pepperoni.jpg",
          "action": {
            "type": "navigate",
            "target": "/product/42"
          }
        }
      ]
    },
    {
      "id": "sticky_categories",
      "type": "horizontal_category_bar",
      "properties": {
        "sticky": true
      },
      "items": [
        { "id": 1, "slug": "pizza", "title": "Pizza", "icon": "pizza" },
        { "id": 2, "slug": "drinks", "title": "Ichimliklar", "icon": "drink" }
      ]
    },
    {
      "id": "pizza_products",
      "type": "product_grid",
      "properties": {
        "columns": 2,
        "category_slug": "pizza"
      },
      "items": [ ... ]
    }
  ]
}
```

### High-Performance Backend Caching (Laravel)
- Utilize Redis tag-based caching:
  ```php
  $cacheKey = "sdui_page_{$screenId}_b{$branchId}_{$locale}";
  return Cache::tags(['sdui', "branch_{$branchId}", "sdui_page_{$screenId}"])
      ->remember($cacheKey, now()->addMinutes(10), function () use ($screenId, $branchId, $locale) {
          return (new SDUIScreenBuilder($screenId, $branchId, $locale))->build();
      });
  ```
- **Cache Invalidation:** Automatically flush `Cache::tags("branch_{$branchId}")` or `Cache::tags("sdui")` when menus, stop-lists, or banners are updated in Filament Admin.
- **HTTP ETag & 304 Not Modified:** Return `ETag` headers; respond with `304 Not Modified` when `If-None-Match` matches, saving mobile data.

---

## 3. Flutter Client Architecture (`strada-flutter`)

### Central Pre-Compiled Component Registry
Located at: `lib/core/sdui/registry/sdui_component_registry.dart`
- Maps string `type` identifiers strictly to pre-compiled Flutter slivers or widgets.
- Registered core components:
  - `carousel_slider` -> `SDUISliderComponent`
  - `horizontal_category_bar` -> `SDUICategoryBarComponent` (with `SliverPersistentHeader` pinned support)
  - `delivery_bar` -> `SDUIDeliveryBarComponent`
  - `announcement` -> `SDUIAnnouncementComponent`
  - `product_grid` -> `SDUIProductGridComponent`
  - `section_header` -> `SDUISectionHeaderComponent`

### Graceful Fallbacks & Error Boundaries
Located at: `lib/core/sdui/registry/sdui_error_boundary.dart`
1. **`SDUISafeErrorBoundary`:**
   - Wraps every dynamic section.
   - Catches unexpected rendering/parsing exceptions within an isolated component to prevent entire screen crashes.
2. **`SDUIUnknownComponentFallback`:**
   - If the server introduces a newer component type not yet known to the current binary version:
     - In **Debug mode**: renders an informative warning banner (`SDUI Fallback: [type] not recognized`).
     - In **Production mode**: silently renders `const SizedBox.shrink()`, ensuring all remaining sections render without user-facing disruption.

### Multi-Tier Offline Caching & SWR (Stale-While-Revalidate)
Located at: `lib/core/sdui/storage/sdui_cache_manager.dart`
- **Instant Rendering (Zero Blank Screen):**
  1. Load cached screen JSON from local storage (`getCachedPage(screenId, branchId)`) and render immediately.
  2. Send asynchronous background network request with HTTP `If-None-Match: <cached_etag>`.
  3. If server returns `304 Not Modified`: Keep existing cached UI.
  4. If server returns `200 OK`: Save updated JSON via `savePage(...)` and smoothly update UI.
  5. If device is offline: Keep rendering cached UI seamlessly.

---

## 4. Development Workflow & Rules

1. **Schema-First Design:** Never build a frontend widget without first defining the JSON contract in this document.
2. **Backward Compatibility:** When adding new fields or components to the backend SDUI output, ensure older app versions ignore unknown keys gracefully without crashing.
3. **No Direct Business Logic in Views:** Component widgets must be purely presentation-driven, receiving props and dispatching actions through `SDUIActionDispatcher`.
4. **Localization:** All human-facing strings must come through Laravel's `trans()` / `HasTranslations` models or Flutter's `easy_localization`.

