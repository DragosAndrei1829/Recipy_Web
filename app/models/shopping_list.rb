# frozen_string_literal: true

class ShoppingList < ApplicationRecord
  belongs_to :user
  has_many :shopping_list_items, dependent: :destroy

  STATUSES = %w[active completed archived].freeze

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }
  scope :archived, -> { where(status: "archived") }

  def complete!
    update!(status: "completed", completed_at: Time.current)
  end

  def archive!
    update!(status: "archived")
  end

  def progress_percentage
    return 0 if items_count.zero?
    (checked_items_count.to_f / items_count * 100).round
  end

  def generate_from_meal_plans!(meal_plans)
    # Parse ingredients from recipes and aggregate them
    ingredients_hash = {}
    
    meal_plans.each do |meal_plan|
      recipe = meal_plan.recipe
      servings = meal_plan.servings
      
      # Parse ingredients from recipe.ingredients (assuming it's a text field with line breaks)
      recipe.ingredients.split("\n").reject(&:blank?).each do |ingredient_line|
        ingredient_line = ingredient_line.strip
        next if ingredient_line.blank?
        
        # Try to parse quantity and name (e.g., "2 cups flour" or "500g sugar")
        parsed = parse_ingredient(ingredient_line, servings)
        
        key = parsed[:name].downcase
        if ingredients_hash[key]
          # Aggregate quantities
          ingredients_hash[key] = aggregate_quantities(ingredients_hash[key], parsed)
        else
          ingredients_hash[key] = parsed
        end
      end
    end
    
    # Create shopping list items
    ingredients_hash.each do |_key, ingredient|
      shopping_list_items.create!(
        ingredient_name: ingredient[:name],
        quantity: ingredient[:quantity],
        unit: ingredient[:unit],
        category: categorize_ingredient(ingredient[:name]),
        position: shopping_list_items.count
      )
    end
    
    update!(items_count: shopping_list_items.count)
  end

  private

  def parse_ingredient(line, servings_multiplier = 1)
    # Simple parsing - can be improved
    # Examples: "2 cups flour", "500g sugar", "1 onion"
    line = line.strip
    
    # Try to extract quantity and unit
    if line.match?(/^\d+([.,]\d+)?/)
      parts = line.split(/\s+/, 3)
      quantity = parts[0].gsub(',', '.').to_f * servings_multiplier
      unit = parts[1] if parts.length > 2 && !parts[1].match?(/^[a-z]/i)
      name = parts[unit ? 2 : 1..-1]&.join(' ') || parts[1]
      
      {
        name: name&.strip || line,
        quantity: quantity == quantity.to_i ? quantity.to_i.to_s : quantity.to_s,
        unit: unit&.strip
      }
    else
      {
        name: line,
        quantity: nil,
        unit: nil
      }
    end
  end

  def aggregate_quantities(existing, new_ingredient)
    # Simple aggregation - if same unit, add quantities
    if existing[:unit] == new_ingredient[:unit] && existing[:quantity] && new_ingredient[:quantity]
      begin
        existing_qty = existing[:quantity].to_f
        new_qty = new_ingredient[:quantity].to_f
        total = existing_qty + new_qty
        {
          name: existing[:name],
          quantity: total == total.to_i ? total.to_i.to_s : total.to_s,
          unit: existing[:unit]
        }
      rescue
        existing
      end
    else
      # Different units or can't aggregate - keep both
      {
        name: existing[:name],
        quantity: "#{existing[:quantity]} #{existing[:unit]} + #{new_ingredient[:quantity]} #{new_ingredient[:unit]}",
        unit: nil
      }
    end
  end

  def categorize_ingredient(name)
    name_lower = name.downcase
    
    categories = {
      vegetables: %w[ceapă roșie cartofi morcovi roșii ardei castraveți varză salată spanac broccoli],
      fruits: %w[mere banane portocale struguri căpșuni],
      meat: %w[carne pui porc vită pește],
      dairy: %w[lapte brânză smântână iaurt unt ouă],
      grains: %w[făină pâine orez paste],
      spices: %w[sare piper cimbru cimbru oregano],
      other: []
    }
    
    categories.each do |category, keywords|
      return category.to_s if keywords.any? { |keyword| name_lower.include?(keyword) }
    end
    
    "other"
  end
end

