# Recipy - Complete Redesign Plan

## Vision
Simplificare totală a interfeței, inspirată de office.com, cu focus pe conținut și accesibilitate.

## 1. Theme System - DOAR 3 Teme ✅

### Light Theme
- Background: `#ffffff` (alb pur)
- Text: `#000000` (negru pur)
- Accent: `#10b981` (emerald-500)

### Dark Theme
- Background: `#1f1f1f` (gri foarte închis)
- Text: `#f5f5dc` (beige/cream)
- Accent: `#34d399` (emerald-400)

### System
- Detectează automat preferința OS-ului
- Folosește `prefers-color-scheme: dark`

## 2. Layout Structure - Office.com Style

```
┌─────────────────────────────────────────────┐
│  [Sidebar Stânga - 240px]  │  [Content]    │
│                             │               │
│  - Logo (top)              │  Feed/Content │
│  - Navigation              │               │
│  - Quick Actions           │               │
│  - Profile (bottom)        │               │
│                             │               │
└─────────────────────────────────────────────┘
```

### Sidebar Stânga (240px)
- **Top**: Logo Recipy
- **Middle**: 
  - Home
  - Recipes
  - Favorites
  - Collections
  - Groups
  - Challenges
  - AI Chef
  - Meal Planner
- **Bottom**: 
  - Profile Icon (ca Microsoft)
  - Settings
  - Theme Toggle (Light/Dark/System)

## 3. Button Styles - Minimalist

### Default State
- Text simplu, fără background
- Culoare: inherit from theme

### Hover State
- Linie subțire sub text
- Culoare linie: alb (dark theme) sau negru (light theme)
- Transition smooth (200ms)

```css
.btn-minimal {
  background: none;
  border: none;
  padding: 0.5rem 0;
  position: relative;
}

.btn-minimal::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  width: 0;
  height: 1px;
  background: currentColor;
  transition: width 200ms ease;
}

.btn-minimal:hover::after {
  width: 100%;
}
```

## 4. Content Area - Posts Primary

### Feed Layout
- **Single column** (max-width: 680px)
- **Centered** on page
- **No sidebars** by default
- **Filters**: Collapsible panel (top-right icon)
- **Top Recipes**: Small badge/indicator, not prominent

### Recipe Card - Minimalist
- White background (light) / Dark gray (dark)
- Simple border: 1px solid
- Clean spacing
- No excessive shadows or gradients
- Focus on image + title + quick stats

## 5. Auth Pages - No Top Bar ✅

- Login/Signup folosesc layout separat (`auth.html.erb`)
- Fără navbar
- Split screen design (imagine stânga, form dreapta)
- Simplu și curat

## 6. Mobile Responsive

### Mobile Sidebar
- Hamburger menu (top-left)
- Sidebar slide-in from left
- Overlay dark pentru focus
- Profile icon rămâne bottom-left în sidebar

## 7. Implementation Steps

### Phase 1: Theme Simplification ✅
- [x] Create `auth.html.erb` layout
- [x] Remove top bar from login/signup
- [ ] Simplify Theme model (keep only Light, Dark)
- [ ] Add System theme detection
- [ ] Update CSS variables

### Phase 2: Sidebar Layout
- [ ] Create new sidebar component
- [ ] Implement office.com style navigation
- [ ] Move profile to bottom-left
- [ ] Add theme switcher (3 options)

### Phase 3: Button Redesign
- [ ] Create `.btn-minimal` class
- [ ] Update all buttons to use new style
- [ ] Implement underline hover effect

### Phase 4: Content Simplification
- [ ] Remove excessive sidebars from feed
- [ ] Make posts primary focus
- [ ] Simplify filters (collapsible)
- [ ] Reduce prominence of "Top Recipes"

### Phase 5: Color Scheme
- [ ] Update Light theme colors
- [ ] Update Dark theme colors
- [ ] Remove all custom themes
- [ ] Test contrast ratios (WCAG AA)

### Phase 6: Testing
- [ ] Test all pages with new layout
- [ ] Test mobile responsiveness
- [ ] Test theme switching
- [ ] Test accessibility

## 8. Design Principles

1. **Simplicity First**: Dacă nu e necesar, nu-l include
2. **Content is King**: Posturile sunt prioritatea #1
3. **Accessibility**: Toate funcțiile trebuie accesibile, dar nu în față
4. **Consistency**: Același design pattern peste tot
5. **Performance**: Minimalist = mai rapid

## 9. Inspiration

- **office.com**: Sidebar navigation, profile bottom-left
- **Linear.app**: Minimalist buttons, clean spacing
- **Notion**: Simple, content-focused
- **GitHub**: Dark/Light themes done right

## 10. Next Steps

1. Finish theme simplification
2. Create sidebar component
3. Update button styles
4. Simplify feed layout
5. Test & iterate
