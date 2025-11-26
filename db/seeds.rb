# Fixed Categories - Cannot be modified by users
fixed_categories = [ "Mic dejun", "Pranz", "Gustare", "Cina", "Shake", "Desert" ]
fixed_categories.each do |name|
  Category.find_or_create_by!(name: name)
end

# Fixed Cuisines (Regiuni) - Cannot be modified by users
fixed_cuisines = [
  "Mediteranean", "Traditional", "Japoneza", "Asiatica", "Italiana",
  "Franceza", "Mexicana", "Indiana", "Chineza", "Thailandeza",
  "Greceasca", "Spaniola", "Turceasca", "Araba", "Americana",
  "Brazileana", "Germana", "Britanica", "Scandinava", "Orientala"
]
fixed_cuisines.each do |name|
  Cuisine.find_or_create_by!(name: name)
end

# Fixed Food Types - Comprehensive list
fixed_food_types = [
  "Vegetariana", "Vegana", "Fara Gluten", "Fara Lactoza", "Keto",
  "Paleo", "Low Carb", "High Protein", "Low Fat", "Raw",
  "Halal", "Kosher", "Picanta", "Dulce", "Sarata",
  "Acrisoara", "Aroma", "Cald", "Rece", "Cruda",
  "Fierta", "Prajita", "La Cuptor", "La Gratar", "La Abur",
  "Supa", "Salata", "Sandwich", "Pizza", "Paste",
  "Carne", "Peste", "Pui", "Porc", "Vita",
  "Oua", "Branza", "Lactate", "Fructe", "Legume",
  "Cereale", "Leguminoase", "Nuci", "Seminte", "Condimente"
]
fixed_food_types.each do |name|
  FoodType.find_or_create_by!(name: name)
end
