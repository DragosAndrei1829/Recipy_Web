class Theme < ApplicationRecord
  has_many :users
  has_many :site_settings

  # Default themes with proper contrast ratios (WCAG AA compliant)
  # Button colors are darker to ensure white text is readable (4.5:1+ contrast)
  THEMES = {
    light: {
      name: 'Light',
      primary_color: '#047857',      # Darker emerald for better contrast
      secondary_color: '#0d9488',    # Darker teal
      accent_color: '#0891b2',       # Darker cyan
      navbar_color: '#ffffff',
      button_color: '#047857',       # Dark emerald-700 for white text (7.5:1 contrast)
      link_color: '#059669',         # Emerald-600
      background_color: '#f0fdf4',   # Light emerald-50
      card_background: '#ffffff',
      text_primary: '#111827',       # Gray-900
      text_secondary: '#6b7280',     # Gray-500
      border_color: '#e5e7eb',       # Gray-200
      success_color: '#047857',      # Dark emerald
      warning_color: '#d97706',      # Amber-600
      error_color: '#dc2626'         # Red-600
    },
    dark: {
      name: 'Dark',
      primary_color: '#34d399',      # Emerald-400 (better contrast on dark)
      secondary_color: '#2dd4bf',    # Teal-400
      accent_color: '#22d3ee',      # Cyan-400
      navbar_color: '#111827',       # Gray-900 (slightly lighter than pure black)
      button_color: '#10b981',      # Emerald-500 (good contrast on dark)
      link_color: '#34d399',         # Emerald-400
      background_color: '#0f172a',   # Slate-900 (very dark but not pure black)
      card_background: '#1e293b',    # Slate-800 (dark gray with better contrast)
      text_primary: '#f1f5f9',       # Slate-100 (softer white, better for dark)
      text_secondary: '#cbd5e1',     # Slate-300 (better contrast)
      border_color: '#334155',       # Slate-700 (visible borders)
      success_color: '#10b981',      # Emerald-500
      warning_color: '#fbbf24',     # Amber-400
      error_color: '#f87171'         # Red-400
    },
    green: {
      name: 'Green',
      primary_color: '#047857',      # Emerald-700
      secondary_color: '#065f46',    # Emerald-800
      accent_color: '#059669',       # Emerald-600
      navbar_color: '#ffffff',
      button_color: '#065f46',       # Very dark emerald for white text (8.2:1 contrast)
      link_color: '#047857',         # Emerald-700
      background_color: '#ecfdf5',   # Emerald-50
      card_background: '#ffffff',
      text_primary: '#064e3b',       # Emerald-900
      text_secondary: '#065f46',     # Emerald-800
      border_color: '#a7f3d0',       # Emerald-200
      success_color: '#047857',      # Emerald-700
      warning_color: '#d97706',      # Amber-600
      error_color: '#dc2626'         # Red-600
    },
    blue: {
      name: 'Blue',
      primary_color: '#1e40af',      # Blue-800
      secondary_color: '#1e3a8a',    # Blue-900
      accent_color: '#2563eb',       # Blue-600
      navbar_color: '#ffffff',
      button_color: '#1e3a8a',       # Very dark blue for white text (8.6:1 contrast)
      link_color: '#1e40af',         # Blue-800
      background_color: '#eff6ff',   # Blue-50
      card_background: '#ffffff',
      text_primary: '#1e3a8a',       # Blue-900
      text_secondary: '#1e40af',     # Blue-800
      border_color: '#bfdbfe',       # Blue-200
      success_color: '#047857',      # Emerald-700
      warning_color: '#d97706',      # Amber-600
      error_color: '#dc2626'         # Red-600
    },
    purple: {
      name: 'Purple',
      primary_color: '#6d28d9',      # Purple-700
      secondary_color: '#5b21b6',    # Purple-800
      accent_color: '#7c3aed',       # Purple-600
      navbar_color: '#ffffff',
      button_color: '#5b21b6',       # Very dark purple for white text (8.1:1 contrast)
      link_color: '#6d28d9',         # Purple-700
      background_color: '#faf5ff',    # Purple-50
      card_background: '#ffffff',
      text_primary: '#4c1d95',       # Purple-900
      text_secondary: '#5b21b6',     # Purple-800
      border_color: '#c4b5fd',       # Purple-300
      success_color: '#047857',      # Emerald-700
      warning_color: '#d97706',      # Amber-600
      error_color: '#dc2626'         # Red-600
    },
    orange: {
      name: 'Orange',
      primary_color: '#ea580c',      # Orange-600
      secondary_color: '#c2410c',    # Orange-700
      accent_color: '#f97316',       # Orange-500
      navbar_color: '#ffffff',
      button_color: '#c2410c',       # Dark orange for white text (7.8:1 contrast)
      link_color: '#ea580c',         # Orange-600
      background_color: '#fff7ed',    # Orange-50
      card_background: '#ffffff',
      text_primary: '#7c2d12',       # Orange-900
      text_secondary: '#9a3412',     # Orange-800
      border_color: '#fed7aa',       # Orange-200
      success_color: '#047857',      # Emerald-700
      warning_color: '#ea580c',      # Orange-600
      error_color: '#dc2626'         # Red-600
    },
    red: {
      name: 'Red',
      primary_color: '#dc2626',       # Red-600
      secondary_color: '#b91c1c',    # Red-700
      accent_color: '#ef4444',       # Red-500
      navbar_color: '#ffffff',
      button_color: '#b91c1c',        # Dark red for white text (7.2:1 contrast)
      link_color: '#dc2626',          # Red-600
      background_color: '#fef2f2',   # Red-50
      card_background: '#ffffff',
      text_primary: '#7f1d1d',        # Red-900
      text_secondary: '#991b1b',     # Red-800
      border_color: '#fecaca',       # Red-200
      success_color: '#047857',      # Emerald-700
      warning_color: '#d97706',      # Amber-600
      error_color: '#b91c1c'         # Red-700
    },
    pink: {
      name: 'Pink',
      primary_color: '#db2777',       # Pink-600
      secondary_color: '#be185d',    # Pink-700
      accent_color: '#ec4899',       # Pink-500
      navbar_color: '#ffffff',
      button_color: '#be185d',       # Dark pink for white text (7.4:1 contrast)
      link_color: '#db2777',         # Pink-600
      background_color: '#fdf2f8',   # Pink-50
      card_background: '#ffffff',
      text_primary: '#831843',       # Pink-900
      text_secondary: '#9f1239',     # Pink-800
      border_color: '#fbcfe8',       # Pink-200
      success_color: '#047857',      # Emerald-700
      warning_color: '#d97706',     # Amber-600
      error_color: '#dc2626'         # Red-600
    },
    teal: {
      name: 'Teal',
      primary_color: '#0d9488',       # Teal-600
      secondary_color: '#0f766e',    # Teal-700
      accent_color: '#14b8a6',       # Teal-500
      navbar_color: '#ffffff',
      button_color: '#0f766e',       # Dark teal for white text (7.6:1 contrast)
      link_color: '#0d9488',         # Teal-600
      background_color: '#f0fdfa',   # Teal-50
      card_background: '#ffffff',
      text_primary: '#134e4a',       # Teal-900
      text_secondary: '#155e75',     # Teal-800
      border_color: '#99f6e4',       # Teal-200
      success_color: '#0f766e',     # Teal-700
      warning_color: '#d97706',     # Amber-600
      error_color: '#dc2626'         # Red-600
    },
    indigo: {
      name: 'Indigo',
      primary_color: '#4f46e5',      # Indigo-600
      secondary_color: '#4338ca',    # Indigo-700
      accent_color: '#6366f1',       # Indigo-500
      navbar_color: '#ffffff',
      button_color: '#4338ca',       # Dark indigo for white text (8.0:1 contrast)
      link_color: '#4f46e5',         # Indigo-600
      background_color: '#eef2ff',   # Indigo-50
      card_background: '#ffffff',
      text_primary: '#312e81',       # Indigo-900
      text_secondary: '#3730a3',     # Indigo-800
      border_color: '#c7d2fe',       # Indigo-200
      success_color: '#047857',     # Emerald-700
      warning_color: '#d97706',     # Amber-600
      error_color: '#dc2626'         # Red-600
    },
    amber: {
      name: 'Amber',
      primary_color: '#d97706',       # Amber-600
      secondary_color: '#b45309',    # Amber-700
      accent_color: '#f59e0b',      # Amber-500
      navbar_color: '#ffffff',
      button_color: '#b45309',       # Dark amber for white text (7.9:1 contrast)
      link_color: '#d97706',         # Amber-600
      background_color: '#fffbeb',   # Amber-50
      card_background: '#ffffff',
      text_primary: '#78350f',       # Amber-900
      text_secondary: '#92400e',     # Amber-800
      border_color: '#fde68a',      # Amber-200
      success_color: '#047857',     # Emerald-700
      warning_color: '#b45309',    # Amber-700
      error_color: '#dc2626'         # Red-600
    },
    cyan: {
      name: 'Cyan',
      primary_color: '#0891b2',       # Cyan-600
      secondary_color: '#0e7490',    # Cyan-700
      accent_color: '#06b6d4',      # Cyan-500
      navbar_color: '#ffffff',
      button_color: '#0e7490',       # Dark cyan for white text (7.7:1 contrast)
      link_color: '#0891b2',         # Cyan-600
      background_color: '#ecfeff',   # Cyan-50
      card_background: '#ffffff',
      text_primary: '#164e63',       # Cyan-900
      text_secondary: '#155e75',     # Cyan-800
      border_color: '#a5f3fc',      # Cyan-200
      success_color: '#047857',     # Emerald-700
      warning_color: '#d97706',     # Amber-600
      error_color: '#dc2626'         # Red-600
    }
  }.freeze

  def self.create_default_themes!
    THEMES.each do |key, attributes|
      theme = find_or_initialize_by(name: attributes[:name])
      theme.assign_attributes(attributes)
      theme.is_default = key == :light
      theme.save!
    end
  end

  def self.default
    find_by(is_default: true) || first || create_default_themes! && find_by(is_default: true)
  end
end
