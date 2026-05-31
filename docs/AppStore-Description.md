# App Store Description — Lumyra

---

**Description**

---

Your phone is the softest light you already own.

Lumyra turns your entire iPhone screen into a beautiful, customizable fill light for selfies, portraits, and video. No ring light. No bulky gear. No harsh flash that washes you out. Just a warm, flattering glow that wraps around your face — wrapped in a dreamy anime night sky.

Photographers spend hundreds on softboxes and LED panels to get one thing: soft, directional, coloured light. Lumyra gives you exactly that, using the screen already in your hand. Your phone becomes the light source — and it's the most versatile one you'll ever carry.

Pick from 8 hand-crafted cinematic presets — from the pink blush of Sakura Breeze to the warm gold of Golden Hour — or create your own with our full HSL colour wheel. Every colour you choose becomes the app itself: the background glows, the shutter button harmonizes, even the floating sparkle particles shift to match your palette. Lumyra isn't just a utility. It's an experience.

---

## ✦ 8 Cinematic Presets, Each With a Story

**Sakura Breeze** — soft petal pink melting into warm peachy-rose. Like cherry blossoms catching the last light of spring.

**Golden Hour** — luminous yellow-gold cascading into deep amber-orange. That impossibly warm light photographers chase every sunset.

**Aurora Purple** — blue-violet fading into rich plum. The colour of a northern-lights sky, electric and dreamlike.

**Coral Reef** — peachy coral blushing into warm terracotta-red. Sun-warmed skin tones, underwater warmth.

**Glacier Blue** — pale icy cyan drifting into crisp sky-blue. Clean, cool, and crystalline.

**Matcha Mist** — soft yellow-green deepening into vibrant emerald. Fresh, natural, and gently luminous.

**Smoky Silver** — warm white-grey settling into cool stone. Understated, elegant, and neutral — a clean base for any scene.

**Deep Sea Glow** — dark teal sinking into abyssal blue-green. Moody, dramatic, and cinematic.

Each preset is a carefully tuned primary-secondary colour pair. Every pair is calibrated for perceived luminance, so text and UI controls remain readable no matter which preset you choose. Swipe left or right anywhere on the glow to cycle through presets instantly — no need to open a menu.

All 8 preset names are fully localized into English, 简体中文 (e.g. "樱花微醺"), 한국어 ("사쿠라 브리즈"), and 日本語 ("桜そよ風"). The poetry translates.

---

## ✦ 3 Light Modes, Infinite Moods

**Solid Mode** — a single, pure colour fills the screen. Clean light with no gradients, no transitions. Perfect when you want one consistent tone across your whole face.

**Gradient Mode** — two colours blend seamlessly from one edge of the screen to the other. Soft transitions create depth: a warm top fading into a cool bottom mimics natural skylight. A pink-to-gold gradient feels like magic hour in your pocket.

**Dual Mode** — a crisp, deliberate split between two colours. Half your screen glows coral, half glows teal. The boundary between them creates directional light: one side of your face catches one temperature, the other catches its complement. Dramatic, creative, and impossible to achieve with any single-point light source.

All three modes support 4 split directions:

• **Vertical** — top-to-bottom, the most natural direction (sky above, ground below)
• **Horizontal** — left-to-right, for creative side-lighting effects
• **Diagonal ↙** — from top-left to bottom-right
• **Diagonal ↘** — from top-right to bottom-left

That's 3 modes × 4 directions = 12 distinct lighting geometries. Each one changes how light falls across your face.

---

## ✦ Unlimited Custom Colours — The Full HSL Colour Wheel

A colour wheel rendered at 4K-equivalent resolution. Every pixel is a true HSL coordinate — pick any hue, any saturation, and Lumyra extracts the exact colour in real time. Drag your finger across the wheel, watch the crosshair follow, and see your screen light shift instantly.

**Two-colour editing.** When Gradient or Dual mode is active, you get two swatches — Primary and Secondary. Tap either to make it the active colour, then spin the wheel. A brightness slider sits below the wheel, letting you dial in the exact luminance from faint glow to full brilliance.

**Save your creations.** Every custom preset you design gets a dedicated card in your library. Long-press to enter delete mode, tap the edit button to refine, or tap to select. Custom presets persist across launches — they're yours forever.

Lumyra comes with unlimited custom preset slots. Your colour. Your mood. Your signature light.

---

## ✦ Designed Like a Magical-Girl Transformation Sequence

Most utility apps look like spreadsheets. Lumyra looks like an anime night sky.

**Deep navy-indigo base.** A multi-stop gradient from midnight violet (#0F0A24) through deep indigo to near-black. Dark enough to make colours pop, layered enough to feel alive.

**Floating sparkle particle system.** Powered by TimelineView + Canvas — not a canned animation loop. Each sparkle has its own speed, phase, scale, and opacity. They drift gently along sine-wave paths, twinkle independently, and render as four-point diamond glints with soft outer glows. The particle cache is pre-generated, so there's zero runtime overhead.

**"Kirakira" star flares.** The iconic four-pointed cross-shaped stars from anime night skies. Each flare has horizontal, vertical, and diagonal diffraction spikes with a bright white core and coloured halo. Their opacity oscillates on independent cycles — they breathe.

**Nebula glows.** Two soft radial gradients — sakura-pink in the upper-right, night-teal in the lower-left — blurred and screen-blended at low opacity. The effect is a subtle celestial haze that never distracts from the light.

**Glass-morphism panels.** Headers and overlays use `.ultraThinMaterial` with subtle warm-gold gradient washes and hairline borders at 6% white. They float above the content rather than boxing it in.

**The colour follows you everywhere.** Select a preset, and its colour doesn't just fill the background — it tints the brightness slider, radiates from the shutter ring, and glows as a soft shadow behind the viewfinder. The contrast colour for every text label is calculated using ITU-R BT.709 luminance — white text on dark presets, dark text on bright ones. Everything is readable, always.

**Haptic feedback on every meaningful interaction.** Light taps for preset switches and mode changes. A satisfying heavy thud for the shutter. Medium impacts for entering delete mode. Each haptic is a pre-prepared `UIImpactFeedbackGenerator` instance — zero latency between gesture and feedback.

---

## ✦ Viewfinder & Photo Capture

A 240pt × 320pt (4:3) live viewfinder sits at the centre of the screen, framed by rounded corners and a coloured glow shadow that matches your active preset. The camera defaults to the front-facing lens for selfies — because that's what fill-light photography is for.

**Shutter button.** A 74pt ring with an angular gradient that harmonizes with your current preset, surrounding a 60pt white button core with a subtle sparkle icon. Pressing it triggers the heavy haptic, captures a photo via AVCapturePhotoOutput, auto-saves it to your Photo Library, and displays an animated preview — the captured image appears in a glass-morphism card with sparkle flourishes and fades after 2.5 seconds.

**Mirror toggle.** A translucent glass button flips the viewfinder preview horizontally. Your selfie framing looks natural — no reversed text, no uncanny asymmetry.

**Camera lifecycle.** The camera session starts on a background thread after the UI renders, so Lumyra launches instantly. It auto-stops when the app enters the background (saving battery) and auto-restarts on foreground (ready when you are). Permission handling is standard and respectful — denied access shows a clear alert with a direct link to Settings.

---

## ✦ Thoughtful Details

**Instant preset switching.** Spring animations (response 0.4s, damping 0.7) make every preset change feel physical and satisfying.

**Brightness slider with live percentage.** A tinted slider (0–100%) flanked by the current preset's colour in a glowing circle and a numeric readout. Drag to adjust — the screen brightness changes in real time. Defaults to 88%, saving both your eyes and your battery.

**Context menus.** Long-press any custom preset to reveal Edit and Delete actions. Built-in presets are protected — you can't accidentally modify or remove them.

**Empty states with purpose.** When you have no custom presets, the custom section shows a single "New" card with a dashed gradient border — an invitation, not a void.

**Section dividers that sparkle.** The divider between Built-in and Custom sections is a thin line broken by a tiny sparkle icon at centre. Even the dividers are designed.

**Performance-first architecture.** The colour wheel image is cached statically after first render. Sparkle particle positions are pre-generated and cached per count. The camera session is configured on a background serial queue. The brightness IOKit call is deferred to the next run-loop iteration so the first frame renders before any hardware transition. Lumyra is built to feel light.

---

## ✦ Four Languages, Natively Localized

English · 简体中文 · 한국어 · 日本語

This is not a machine-translated app. Every preset name, every UI label, every alert message, and every language-picker entry is hand-written. The Chinese preset names are poetic ("樱花微醺" — cherry blossom tipsy). The Japanese names capture the original mood ("桜そよ風" — sakura gentle breeze). The Korean names preserve rhythm and beauty ("사쿠라 브리즈").

The language switcher is always one tap away — a subtle globe icon near the brightness slider. Switch languages without leaving the camera, without digging through system settings.

---

**Lumyra is free to download and use.** All 8 built-in presets. All 3 light modes. All 4 split directions. The full HSL colour wheel. All 4 languages. The entire anime night sky.

**Lumyra Pro** — a one-time unlock, not a subscription — gives you unlimited custom preset slots and early access to exclusive seasonal colour drops (autumn leaves, winter aurora, spring cherry blossom, summer ocean).

---

Your phone. Perfectly lit. Infinitely yours.

**Download Lumyra.**
