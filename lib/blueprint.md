# NovaTek UI Blueprint

## 1. Core Philosophy
The NovaTek UI is built on a clean, modern, and data-dense aesthetic. It relies heavily on soft borders, subtle contrasting backgrounds, and stark typography to create an enterprise-grade clinical trial interface.

*   **Flat & Deep:** Surfaces are mostly flat, using borders to define edges. Shadows are reserved strictly for floating elements (dialogs, dropdowns, floating badges).
*   **Tactile Feedback:** Every interactive element must respond to user input via subtle color shifts or scale animations.
*   **Data Clarity:** Data points are bold and dark; structural text (labels, "Showing X to Y") is muted to guide the user's eye directly to the numbers.

---

## 2. Color Palette (The "Slate" Foundation)

Our theme is driven by a unified gray palette (Slate) mixed with semantic status colors.

### Base & Surfaces
*   **App Background:** `Slate 50 (#F8FAFC)` - Used for the main scaffold background.
*   **Surface:** `White (#FFFFFF)` - Used for cards, dialogs, and main content areas.
*   **Hover/Active Fill:** `Slate 100 (#F1F5F9)` - Used for hovered list items or disabled input backgrounds.

### Borders & Dividers
*   **Light Border:** `Slate 200 (#E2E8F0)` - The standard border for cards, inputs, and tables.
*   **Medium Border/Disabled:** `Slate 300 (#CBD5E1)` - Used for disabled button borders.

### Typography & Icons
*   **Primary Text (Headings/Data):** `Slate 900 (#0F172A)` - High contrast for readability.
*   **Body Text:** `Slate 700 (#334155)` - Standard reading text.
*   **Muted Text/Icons:** `Slate 500 (#64748B)` - Used for secondary labels, hints, and standard inactive icons.
*   **Disabled Text:** `Slate 400 (#94A3B8)`

### Semantic Status
*   **Brand Primary:** `Primary (#1B757A)` or `Sky 500 (#0EA5E9)` depending on active theme.
*   **Success:** `Emerald 500 (#10B981)`
*   **Error / Destructive:** `Rose 500 (#EF4444)`
*   **Warning / Pending:** `Amber 500 (#F59E0B)`
*   **Info:** `Sky 500 (#0EA5E9)`
*   **Cohort / Specialized:** `Indigo 500 (#6366F1)`

---

## 3. Typography Hierarchy
We utilize the `AppTypography` widget set to enforce consistency.

*   **H3Text / H4Text / H5Text:** Used for screen headers, dialog titles, and card headers. Always rendered in `Slate 900`.
*   **BodyTextLarge / BodyTextMedium:** Used for standard descriptions. Rendered in `Slate 700` or `Slate 500` depending on importance.
*   **LabelLargeText / LabelMediumText:** Used for buttons, table headers, and badges. Font weight is typically `w500` or `w600`.
*   **CaptionText / BodyTextSmall:** Used for timestamps and sub-labels.

---

## 4. Component Guidelines

### Cards & Containers
*   **Border Radius:** `12px` or `16px` for large dashboard containers.
*   **Border:** `1.5px` solid `Slate 200`.
*   **Padding:** Standard internal padding is `16px` or `24px`.

### Inputs (`CustomInputField`)
*   **Resting:** `Slate 200` border, `Slate 50` fill.
*   **Focused:** `2.0px` Primary color border, `White` fill.
*   **Error:** `Rose 500` border, `Rose 50 (errorContainer)` fill.
*   **Disabled:** `Slate 200` border at 50% opacity, `Slate 100` fill.

### Buttons & Interactions
*   **Primary Buttons:** Solid fill with `Surface` (White) text.
*   **Secondary Buttons:** Outlined with `Slate 200` border and `Slate 600` text.
*   **Icon Buttons:** Compact visual density, zero padding, splashing with Primary color at `10%` opacity.

---

## 5. Spacing & Layout
*   Always use multiples of 4 or 8.
*   **Tiny:** `4px` / `8px`
*   **Standard:** `16px` (between elements in a card)
*   **Large:** `24px` / `32px` (between major sections or dialog padding)