# 🎨 Recipy Redesign - Minimalist & Accessible

## 🎯 Obiectiv:
Redesign complet bazat pe template Subframe - **ultra minimalist, accesibil, simplu**.

## 📋 Feedback utilizatori:
- ❌ **Prea complicat** - multe butoane, culori, gradients
- ❌ **Greu de navigat** - navbar aglomerat
- ✅ **Animațiile plac** - păstrăm hover/transition effects
- ✅ **Chat-ul e bun** - promovăm mai mult

---

## 🎨 Design System Nou (din template):

### **Colors - Neutral First:**
- **Background**: `bg-default-background` (alb/gri deschis)
- **Cards**: `bg-default-background` cu `border-neutral-300`
- **Text**: `text-default-font` (negru/gri închis)
- **Subtext**: `text-subtext-color` (gri mediu)
- **Accent**: `text-brand-primary` (doar pe hover/active)
- **Shadows**: `shadow-sm` (minimal, nu shadow-2xl)

### **Typography:**
- **Headings**: `text-heading-2` (24px), `text-heading-3` (20px)
- **Body**: `text-body` (16px), `text-body-bold` (16px bold)
- **Caption**: `text-caption` (14px)
- **No excessive font weights** - doar normal și bold

### **Spacing:**
- **Cards**: `px-6 py-6` (24px padding)
- **Gaps**: `gap-4` (16px), `gap-6` (24px)
- **Borders**: `border` (1px), `rounded-md` (6px)
- **No excessive rounded-3xl** - doar rounded-md

### **Components:**
- **Avatar**: Circle, 40px pentru users
- **Badges**: Neutral, `variant="neutral"` - simple pills
- **Buttons**: Minimal, `variant="neutral-secondary"` pentru secondary
- **Icons**: Feather icons (Heart, MessageCircle, Share2, Bookmark)
- **Actions**: Icon + number, hover color change

---

## 📱 Layout Changes:

### **Homepage (Feed):**

**Înainte:**
```
[Sidebar] [Feed with filters/hero] [Sidebar]
```

**După (template):**
```
[Feed - Full Width]  [Trending Sidebar - Desktop Only]
```

**Features:**
- ✅ Single column feed (no left sidebar)
- ✅ Trending sidebar doar pe desktop
- ✅ Cards simple (Avatar + Username + Text + Image + 3 Badges + Actions)
- ✅ Actions: Heart, Comment, Share (no more complex buttons)
- ✅ Bookmark icon (right side)

### **Navbar:**

**Înainte:**
```
[Hamburger] [Logo] [Admin] [Search Bar........] [Notif] [Messages] [Add] [Profile] [Lang]
```

**După:**
```
[Logo "Recipy"]  ········  [Search] [Add] [Notif] [Profile]
```

**Mobile:**
```
[R Logo]  ········  [Search] [Add] [Menu]
```

### **Recipe Card:**

**Înainte:**
```
╔═══════════════╗
║ Avatar + User ║
║ ━━━━━━━━━━━━━ ║
║   IMAGE       ║
║ ━━━━━━━━━━━━━ ║
║ Title (bold)  ║
║ Description   ║
║ ━━━━━━━━━━━━━ ║
║ Stats Bubbles ║
║ ━━━━━━━━━━━━━ ║
║ ❤️💬🔖 [Vezi]  ║
╚═══════════════╝
```

**După (template):**
```
╔═══════════════╗
║ 👤 Username   ║
║    @handle·2h ║
║ ━━━━━━━━━━━━━ ║
║ Text content  ║
║ ━━━━━━━━━━━━━ ║
║   IMAGE       ║
║ ━━━━━━━━━━━━━ ║
║ [Tag] [Tag]   ║
║ ━━━━━━━━━━━━━ ║
║ ❤️234 💬45 🔗12║
╚═══════════════╝
```

**Eliminat:**
- ❌ Gradient backgrounds
- ❌ Multiple shadows
- ❌ "Vezi Rețeta" button (click pe card)
- ❌ Stats bubbles (difficulty, time în card)
- ❌ Complex badges

**Păstrat:**
- ✅ Avatar + Username
- ✅ Image (dacă există)
- ✅ Simple actions (Heart, Comment, Share)
- ✅ 2-3 tags (category, cuisine, time)

---

## 🔄 Migration Plan:

### **Phase 1: Cards & Feed** (Priority 1)
- [ ] Create new `_card_minimal.html.erb`
- [ ] Remove gradients, use neutral colors
- [ ] Simple border (border-neutral-300)
- [ ] Actions: Heart, Comment, Share icons only
- [ ] 3 badges max (category, time, difficulty)
- [ ] Single column layout

### **Phase 2: Navbar** (Priority 2)
- [ ] Desktop: Logo + Search + Add + Notif + Profile (5 items)
- [ ] Mobile: Logo + Search + Add + Menu (4 items)
- [ ] Remove: Admin Hub, Messages, Language switcher (move to menu)
- [ ] Clean background (no gradients)

### **Phase 3: Login/Signup** (Priority 3)
- [ ] Split-screen layout (Image left, Form right)
- [ ] Google OAuth button prominent
- [ ] Email/Password with divider ("OR")
- [ ] Minimal styling (white cards, simple borders)
- [ ] "Forgot password?" link

### **Phase 4: Trending Sidebar** (Priority 4)
- [ ] "What's Cooking" - Top 3 recipes (small cards)
- [ ] "Suggested Chefs" - Top 3 users to follow
- [ ] Desktop only (hidden on mobile)
- [ ] Chat promotion box (NEW!)

### **Phase 5: Chat Promotion** (Priority 5)
- [ ] Add "Start a Conversation" card in sidebar
- [ ] Sparkles icon + "Chat with chefs"
- [ ] "View all chats" button

### **Phase 6: Other Pages** (Keep Simple)
- [ ] View Recipe - keep animations, simplify colors
- [ ] Profile - minimal cards
- [ ] Groups - simple layout
- [ ] Collections - grid minimal

---

## ⏱️ Timeline:

**Session 1 (Acum - 1 oră):**
- ✅ Cards redesign (minimal)
- ✅ Feed layout (single column)
- ✅ Fix mobile images

**Session 2 (Next):**
- Navbar redesign
- Login/Signup pages
- Trending sidebar

**Session 3 (Final):**
- Chat promotion
- Polish & test
- Deploy

---

## 🚀 Starting now!

Implementez redesign-ul pe etape. Fiecare commit = 1 feature gata!

