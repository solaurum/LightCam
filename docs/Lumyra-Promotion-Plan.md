# Lumyra — Go-to-Market Promotion Plan

> **Product**: Lumyra (补光相机) — the anime-themed fill-light camera for iPhone
> **Version**: 1.0
> **Target Markets**: US, China, Japan, South Korea
> **Date**: June 2026

---

## 1. Executive Summary

Lumyra turns your iPhone screen into a **customizable, beautifully animated fill light** for selfies and portrait photos. Instead of harsh flash or expensive ring lights, Lumyra glows with your choice of 8 hand-crafted anime-inspired color presets — or any color you can imagine — giving your photos a soft, flattering, and artistic light.

With a magical-girl / anime-night-sky aesthetic, floating sparkle particles, haptic feedback, and support for 4 languages, Lumyra is designed to stand out in a sea of utilitarian camera apps. It is **not just a tool — it's an experience**.

---

## 2. Product Highlights

### 2.1 Core Value Proposition

| Pain Point | Lumyra Solution |
|---|---|
| Phone flash is harsh and unflattering | Soft, full-screen glow with adjustable brightness (0–100%) |
| Ring lights are bulky and expensive | Your phone *is* the ring light — zero extra hardware |
| Standard fill-light apps look ugly | Anime night-sky theme with sparkle particles, star fields, and glass-morphism UI |
| Can't match light to mood | 8 built-in presets + unlimited custom colors via full HSL color wheel |
| One-size-fits-all lighting | 3 modes (Solid / Gradient / Dual-color) × 4 split directions |

### 2.2 Feature Matrix

| Feature | Description |
|---|---|
| **8 Built-in Presets** | Sakura Breeze, Golden Hour, Aurora Purple, Coral Reef, Glacier Blue, Matcha Mist, Smoky Silver, Deep Sea Glow |
| **3 Light Modes** | Solid (single color), Gradient (smooth blend), Dual (two-tone split) |
| **4 Split Directions** | Horizontal (left-right), Vertical (top-bottom), Diagonal ↙, Diagonal ↘ |
| **Custom Color Editor** | Full HSL color wheel rendered at 4K-equivalent resolution, with brightness slider |
| **Screen Brightness Control** | 0–100% slider with real-time preview, tinted to match the current preset |
| **Live Viewfinder** | 4:3 viewfinder with the current preset's color as a soft glow shadow |
| **Photo Capture** | Tap to capture, auto-saves to Photo Library, animated preview with sparkle flourish |
| **Swipe Gesture** | Swipe left/right on the fill-light background to cycle presets instantly |
| **Mirror Toggle** | Flip the front camera preview for natural selfie framing |
| **Multi-Language** | English, 简体中文, 한국어, 日本語 — localized preset names and all UI strings |
| **Haptic Feedback** | Light/medium/heavy haptics on shutter, preset switch, save, delete, and mode changes |
| **Dark Mode Only** | Designed exclusively for dark mode — deep navy-indigo backgrounds never blind you at night |
| **Anime Aesthetic** | Floating sparkle particle system (TimelineView + Canvas), twinkling star field, "kirakira" star flares, nebula glows, glass-morphism panels |

### 2.3 Technical Excellence

- **Instant launch feel**: Camera session starts on a background thread after the first frame renders — the UI appears instantly
- **4K color wheel**: Rendered once at 4× logical resolution and cached statically; every subsequent open is instant
- **Particle system cache**: Sparkle positions pre-generated and cached per count
- **ITU-R BT.709 luminance**: Contrast colors for text-on-preset are scientifically calculated, not guessed
- **Background/foreground lifecycle**: Camera auto-stops on background, restarts on foreground — battery-friendly
- **Simulator support**: Works in iOS Simulator via `SimulatorCameraClient`

---

## 3. Target Audience

### 3.1 Primary: Aesthetic Selfie Enthusiasts (18–30)

- **Demographic**: Young women, predominantly
- **Behavior**: Take selfies daily, post to Instagram / TikTok / Xiaohongshu (RED) / WeChat Moments
- **Pain point**: Bad lighting ruins good selfies; ring lights are inconvenient to carry
- **Hook**: "Your phone is already in your hand — make it your personal studio light"

### 3.2 Secondary: Content Creators & Streamers

- **Demographic**: Vloggers, live streamers, makeup tutorial creators
- **Behavior**: Need consistent, flattering lighting on-the-go
- **Hook**: 8 cinematic presets inspired by photography's golden-hour and anime color grading

### 3.3 Tertiary: Anime / Otaku Culture Fans

- **Demographic**: Anime fans, cosplayers, J-pop/K-pop enthusiasts
- **Behavior**: Appreciate Japanese/Korean aesthetics, drawn to "kawaii" UI
- **Hook**: The app itself looks like a magical-girl transformation sequence. Every interaction sparkles.

### 3.4 Geographic Priority

| Priority | Market | Rationale |
|---|---|---|
| **Tier 1** | Japan, China | Largest selfie-app cultures; anime aesthetic resonates natively |
| **Tier 2** | South Korea, United States | Strong beauty/selfie culture (KR); large English-speaking audience (US) |
| **Tier 3** | Taiwan, Hong Kong, Southeast Asia | Cultural proximity to both Chinese and Japanese markets |

---

## 4. Brand Voice & Visual Identity

### 4.1 Tone of Voice

- **Whimsical but not childish** — "magical realism" rather than "cartoon"
- **Premium but approachable** — the app is free; the experience feels expensive
- **Multilingual-native** — every string localized, not machine-translated; preset names are poetic in all 4 languages

### 4.2 Key Messages

| Message | Use In |
|---|---|
| *"Your phone is the softest light you already own."* | App Store subtitle, website hero |
| *"8 cinematic presets. Infinite custom colors. One magical glow."* | Feature highlight, social ads |
| *"Not a filter. A light."* | Differentiator (vs. photo filter apps) |
| *"Designed like an anime night sky. Works like a professional fill light."* | Tech blog pitch |
| *"樱花微醺 · ゴールデンアワー · 오로라 퍼플"* (multilingual preset names) | Asian market social posts |

### 4.3 Visual Assets Needed

- [ ] App Store screenshots (6.7" + 6.5" + 5.5") — showing each preset mode with a model selfie
- [ ] App Preview video (30s) — sparkle animations, color wheel, swipe gesture, photo capture
- [ ] Press kit: logo (SVG + PNG), feature icons, lifestyle photos
- [ ] Social media template pack: Instagram story (9:16), TikTok/Reels (9:16), Twitter card (16:9)

---

## 5. Channel Strategy

### 5.1 App Store Optimization (ASO)

**Keywords to target:**
- Primary: `fill light`, `selfie light`, `screen light`, `soft light`, `beauty light`, `补光`, `自拍补光`, `セルフライト`, `셀피 조명`
- Secondary: `ring light alternative`, `anime camera`, `photo light`, `portrait light`, `golden hour light`
- Brand: `Lumyra`, `ルミラ`, `루미라`

**App Store listing:**
- Title: `Lumyra — Anime Fill Light Camera`
- Subtitle: `Soft screen glow for selfies`
- Promotional text: updated bi-weekly with seasonal presets (e.g., "Summer Sunset preset now available")

### 5.2 Social Media

#### Instagram / TikTok (Primary)
- **Content pillars:**
  1. **Before/After**: Side-by-side selfies — no fill light vs. Lumyra (each preset)
  2. **Preset showcase**: 15-second aesthetic clips, each featuring one preset color palette
  3. **Color-matching challenges**: "Match your light to your outfit" user-generated content prompts
  4. **Anime edits**: Clips styled like anime transformations, synced to lo-fi / city pop music
- **Hashtags**: `#LumyraApp` `#FillLight` `#SelfieHack` `#PhoneStudio` `#animeaesthetic` `#补光相机`

#### Xiaohongshu (RED) — China
- "笔记" posts: aesthetic flat-lay photos of iPhone running Lumyra next to makeup/products
- Tutorial-style posts: "How to get golden-hour selfies at midnight"
- Collaborate with 1–2 mid-tier beauty KOLs for authentic reviews

#### Twitter / X (Secondary)
- Dev/design angles: thread on the color wheel rendering, animation system, haptic design
- "Ship list" style launch post for Product Hunt

#### YouTube Shorts / Bilibili
- 60-second vertical demo: unboxing-style "here's an app that lights your face"
- Bilibili: Chinese-subtitled version emphasizing the anime aesthetic and 补光 functionality

### 5.3 Community & PR

#### Product Hunt Launch (Week 1)
- Launch on a Tuesday–Thursday
- Prepare: maker comment story, 5 GIFs, first-comment FAQ
- Target: top 5 of the day, "Camera & Photo" category badge

#### Tech Blog Outreach
- **MacStories**: "A camera app that looks like Sailor Moon designed it"
- **iMore / 9to5Mac**: Roundup of "best indie camera apps of 2026"
- **JiaYu / ShaoNianPai (少数派)**: Chinese tech blog — detailed review with localization angle

#### Reddit
- r/iPhone, r/iOS, r/apple: "I made a fill-light camera app that looks like an anime night sky"
- r/selfie, r/MakeupAddiction: utility angle — "free ring light alternative"
- r/anime, r/MagicalGirls: aesthetic angle — "this app sparkles when you take a photo"

### 5.4 Influencer Seeding

| Tier | Count | Follower Range | Approach |
|---|---|---|---|
| Micro | 15–20 | 5K–50K | Free app + personalized thank-you DM |
| Mid | 5–8 | 50K–500K | Free app + $50–200 honorarium for a dedicated post |
| Macro | 1–2 | 500K+ | Paid partnership ($500–2K) for launch-week feature |

Priority categories: beauty/makeup, cosplay, photography tips, tech/lifestyle

### 5.5 Cross-Promotion

- Reach out to **camera accessory brands** (e.g., phone tripod makers, clip-on lens brands) for bundle giveaways
- **Anime streaming services** (Crunchyroll, Bilibili): propose themed preset pack collaborations (e.g., "Demon Slayer color palette" limited-time preset)

---

## 6. Launch Timeline

### Phase 0: Pre-Launch (Now — 2 weeks before launch)

| Week | Actions |
|---|---|
| **Week -2** | Finalize App Store listing, screenshots, preview video. Submit for review. |
| **Week -1** | Prepare Product Hunt assets. Seed TestFlight to 20 micro-influencers. Schedule social posts. Reach out to tech bloggers with embargoed preview. |

### Phase 1: Launch Week (Week 0)

| Day | Actions |
|---|---|
| **Day 1 (Tue)** | Product Hunt launch. Reddit posts (r/iPhone, r/iOS). First Instagram/TikTok posts go live. |
| **Day 2** | Xiaohongshu note. Twitter thread on design/tech. Respond to all Product Hunt comments. |
| **Day 3** | First influencer posts begin appearing (staggered over 5 days). |
| **Day 5** | Bilibili video. Japanese-market Twitter post. |
| **Day 7** | Week-1 retrospective: gather ratings, reviews, analytics. Adjust ASO keywords. |

### Phase 2: Sustain (Weeks 2–4)

| Week | Actions |
|---|---|
| **Week 2** | Second wave of influencer posts. Submit "New Apps We Love" pitch to App Store editorial. |
| **Week 3** | Release 1.01 patch with any quick fixes. Engage with user feedback publicly. |
| **Week 4** | "One month of Lumyra" — share user-generated before/after photos (with permission). Monthly review of ASO performance. |

### Phase 3: Growth (Months 2–6)

- **Seasonal preset drops**: Halloween (orange/purple dual-tone), Christmas (gold/green gradient), Valentine's (pink/red), Sakura season (Japan/Korea)
- **Referral mechanic**: "Share your Lumyra selfie → unlock a secret preset"
- **Localization expansion**: Add Thai, Vietnamese, Indonesian based on download analytics
- **App Store featuring pitch**: re-submit for seasonal collections ("Apps for Selfie Lovers", "Indie Gems")

---

## 7. Monetization Strategy

| Tier | Price | Includes |
|---|---|---|
| **Free** | $0 | 8 built-in presets, 3 modes, custom color editor, all 4 languages |
| **Lumyra Pro (IAP)** | $2.99 one-time | Unlimited custom preset slots, exclusive seasonal presets, widget support (future) |

> **Principle**: The app should be *genuinely useful* for free. Pro is for enthusiasts who want unlimited creative control. Never paywall core functionality.

### Alternative Monetization Model (if IAP data is weak):
- **Tip Jar**: "Buy the developer a bubble tea" tiers ($0.99 / $2.99 / $5.99) with animated sparkle reactions as thanks

---

## 8. Success Metrics

| Metric | 1-Month Target | 6-Month Target |
|---|---|---|
| Total downloads | 5,000 | 50,000 |
| App Store rating | ≥ 4.5 ⭐ | ≥ 4.6 ⭐ |
| Reviews count | ≥ 100 | ≥ 500 |
| Pro conversion rate | ≥ 3% | ≥ 5% |
| Daily active users (DAU) | 800 | 5,000 |
| Social reach (impressions) | 200K | 1M |
| Product Hunt upvotes | ≥ 300 | — |

---

## 9. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| **Low organic discovery** | Medium | Invest heavily in ASO + influencer seeding; rely less on App Store browse traffic |
| **"Another camera app" fatigue** | Medium | Lead with the anime aesthetic — it's the differentiator. No one forgets a sparkly UI. |
| **Screen brightness burns battery** | Low | Brightness slider defaults to 88% not 100%; optimize with clear battery messaging |
| **Copycat apps** | High (long-term) | Build brand loyalty through aesthetic, community, and seasonal content; ship features fast |
| **App Store rejection** | Low | No private APIs used; camera permission flow is standard; all strings localized |
| **Poor Asian-market reception** | Medium | Already has native-quality Chinese/Japanese/Korean localizations — validate with native speakers pre-launch |

---

## 10. Appendix

### A. Competitor Landscape

| App | Strengths | Weaknesses vs. Lumyra |
|---|---|---|
| Generic fill-light apps | Functional | Ugly UI, no presets, no aesthetic appeal |
| Snapchat / Instagram | Built-in camera | Fill light is an afterthought, not the product |
| Ring light hardware | Professional quality | Expensive ($30–150), bulky, needs charging |
| VSCO / photo editors | Post-processing filters | Can't fix bad lighting at capture time |

**Lumyra's moat**: It's the only fill-light app that *cares about how it looks and feels*. The anime aesthetic, haptics, animations, and multilingual poetry of the preset names create an emotional connection that no generic utility app can match.

### B. Preset Localization Reference

| # | English | 简体中文 | 한국어 | 日本語 |
|---|---|---|---|---|
| 0 | Sakura Breeze | 樱花微醺 | 사쿠라 브리즈 | 桜そよ風 |
| 1 | Golden Hour | 黄金时刻 | 골든 아워 | ゴールデンアワー |
| 2 | Aurora Purple | 极光紫 | 오로라 퍼플 | オーロラパープル |
| 3 | Coral Reef | 珊瑚礁 | 코랄 리프 | コーラルリーフ |
| 4 | Glacier Blue | 冰川蓝 | 글레이셔 블루 | グレイシャーブルー |
| 5 | Matcha Mist | 抹茶雾 | 말차 미스트 | 抹茶ミスト |
| 6 | Smoky Silver | 烟灰银 | 스모키 실버 | スモーキーシルバー |
| 7 | Deep Sea Glow | 深海夜光 | 딥씨 글로우 | ディープシーグロー |

### C. Key URLs (to create)

- Website: `lumyra.app`
- Twitter / X: `@LumyraApp`
- Instagram: `@lumyra.app`
- Email: `hello@lumyra.app`
- Privacy policy: `lumyra.app/privacy`

---

> *"In photography, light is everything. Lumyra puts a studio's worth of soft, colorful light in your pocket — wrapped in an anime night sky."*
