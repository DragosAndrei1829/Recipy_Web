# frozen_string_literal: true

# AI Recipe Assistant Service
# Helps users find or create recipes based on available ingredients
class AiRecipeAssistant
  OPENAI_MODEL = "gpt-4o-mini" # Cost-effective and fast
  MAX_RECIPE_MATCHES = 5
  MIN_INGREDIENT_MATCH_PERCENTAGE = 0.5 # At least 50% of ingredients should match

  def initialize(user: nil)
    @user = user
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  # Main entry point - process user message and return response
  def chat(message, conversation_history: [])
    # Parse the user's request
    parsed_request = parse_user_request(message)
    
    # Find matching existing recipes
    matching_recipes = find_matching_recipes(parsed_request)
    
    # Generate response based on what we found
    generate_response(parsed_request, matching_recipes, conversation_history)
  end

  private

  # Parse user message to extract ingredients and preferences
  def parse_user_request(message)
    prompt = <<~PROMPT
      Analizează acest mesaj de la utilizator și extrage informațiile relevante pentru a găsi sau crea o rețetă.
      
      Mesaj: "#{message}"
      
      Răspunde DOAR în format JSON valid (fără markdown, fără ```):
      {
        "ingredients": ["ingredient1", "ingredient2"],
        "preferences": {
          "healthy": true/false,
          "cooking_method": "cuptor/tigaie/fiert/raw/orice",
          "difficulty": "ușor/mediu/greu/orice",
          "time_limit_minutes": null sau număr,
          "cuisine_type": "românească/italiană/etc sau null",
          "dietary_restrictions": ["vegetarian", "vegan", "fără gluten", etc] sau []
        },
        "additional_context": "orice altă informație relevantă"
      }
    PROMPT

    response = @client.chat(
      parameters: {
        model: OPENAI_MODEL,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3
      }
    )

    content = response.dig("choices", 0, "message", "content")
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse AI response: #{e.message}"
    { "ingredients" => [], "preferences" => {}, "additional_context" => message }
  rescue StandardError => e
    Rails.logger.error "OpenAI API error: #{e.message}"
    { "ingredients" => [], "preferences" => {}, "additional_context" => message }
  end

  # Find existing recipes that match the user's ingredients
  def find_matching_recipes(parsed_request)
    user_ingredients = parsed_request["ingredients"].map(&:downcase).map(&:strip)
    return [] if user_ingredients.empty?

    preferences = parsed_request["preferences"] || {}
    
    # Start with visible recipes
    recipes = Recipe.visible.includes(:user, :category, :cuisine, :food_type)
    
    # Apply preference filters
    recipes = apply_preference_filters(recipes, preferences)
    
    # Score recipes by ingredient match
    scored_recipes = recipes.map do |recipe|
      score = calculate_ingredient_match_score(recipe, user_ingredients)
      { recipe: recipe, score: score, matched_ingredients: score[:matched], missing_ingredients: score[:missing] }
    end

    # Filter and sort by score
    scored_recipes
      .select { |r| r[:score][:percentage] >= MIN_INGREDIENT_MATCH_PERCENTAGE }
      .sort_by { |r| -r[:score][:percentage] }
      .first(MAX_RECIPE_MATCHES)
  end

  def apply_preference_filters(recipes, preferences)
    # Filter by healthiness
    if preferences["healthy"]
      recipes = recipes.where("healthiness >= ?", 3)
    end

    # Filter by difficulty
    case preferences["difficulty"]
    when "ușor"
      recipes = recipes.where("difficulty <= ?", 2)
    when "mediu"
      recipes = recipes.where("difficulty BETWEEN ? AND ?", 2, 4)
    when "greu"
      recipes = recipes.where("difficulty >= ?", 4)
    end

    # Filter by time
    if preferences["time_limit_minutes"].present?
      recipes = recipes.where("time_to_make <= ?", preferences["time_limit_minutes"])
    end

    # Filter by cuisine
    if preferences["cuisine_type"].present?
      cuisine = Cuisine.find_by("LOWER(name) LIKE ?", "%#{preferences['cuisine_type'].downcase}%")
      recipes = recipes.where(cuisine: cuisine) if cuisine
    end

    recipes
  end

  def calculate_ingredient_match_score(recipe, user_ingredients)
    recipe_ingredients = extract_ingredients_from_text(recipe.ingredients)
    
    matched = user_ingredients.select do |user_ing|
      recipe_ingredients.any? { |recipe_ing| ingredient_matches?(user_ing, recipe_ing) }
    end

    missing = recipe_ingredients.reject do |recipe_ing|
      user_ingredients.any? { |user_ing| ingredient_matches?(user_ing, recipe_ing) }
    end

    percentage = user_ingredients.any? ? matched.length.to_f / user_ingredients.length : 0

    { matched: matched, missing: missing.first(5), percentage: percentage, total_recipe_ingredients: recipe_ingredients.length }
  end

  def extract_ingredients_from_text(text)
    return [] if text.blank?
    
    # Split by common separators and clean up
    text.split(/[\n,;•\-\*]/)
        .map(&:strip)
        .reject(&:blank?)
        .map { |i| i.gsub(/^\d+[\s\.]*(g|kg|ml|l|linguri?|lingurițe?|cești?|bucăți?)?[\s\.]*/i, "").strip }
        .reject { |i| i.length < 2 }
        .map(&:downcase)
  end

  def ingredient_matches?(user_ingredient, recipe_ingredient)
    user_ing = user_ingredient.downcase.strip
    recipe_ing = recipe_ingredient.downcase.strip
    
    # Direct match or partial match
    recipe_ing.include?(user_ing) || 
      user_ing.include?(recipe_ing) ||
      similar_ingredients?(user_ing, recipe_ing)
  end

  def similar_ingredients?(ing1, ing2)
    # Common ingredient synonyms/variations
    synonyms = {
      "roșii" => ["tomate", "roșie", "tomată"],
      "cartofi" => ["cartof"],
      "ceapă" => ["cepe"],
      "usturoi" => ["căței de usturoi"],
      "pui" => ["piept de pui", "carne de pui", "pulpe de pui"],
      "vită" => ["carne de vită", "mușchi de vită"],
      "porc" => ["carne de porc", "mușchi de porc"],
      "brânză" => ["cașcaval", "telemea", "parmezan"],
      "smântână" => ["smantana"],
      "lapte" => ["lapte integral", "lapte degresat"],
      "ouă" => ["ou", "gălbenușuri", "albușuri"],
      "făină" => ["faina"],
      "ulei" => ["ulei de măsline", "ulei de floarea soarelui"],
      "orez" => ["orez basmati", "orez cu bob lung"]
    }

    synonyms.each do |_key, values|
      all_variations = values + [_key]
      if all_variations.any? { |v| ing1.include?(v) } && all_variations.any? { |v| ing2.include?(v) }
        return true
      end
    end

    false
  end

  # Generate AI response with recommendations or new recipe
  def generate_response(parsed_request, matching_recipes, conversation_history)
    if matching_recipes.any?
      generate_recommendation_response(parsed_request, matching_recipes)
    else
      generate_new_recipe_response(parsed_request)
    end
  end

  def generate_recommendation_response(parsed_request, matching_recipes)
    recipes_info = matching_recipes.map do |match|
      recipe = match[:recipe]
      {
        id: recipe.id,
        title: recipe.title,
        description: recipe.description&.truncate(100),
        difficulty: recipe.difficulty,
        time_to_make: recipe.time_to_make,
        healthiness: recipe.healthiness,
        likes_count: recipe.likes_count,
        user: recipe.user.username,
        category: recipe.category&.name,
        cuisine: recipe.cuisine&.name,
        match_percentage: (match[:score][:percentage] * 100).round,
        matched_ingredients: match[:matched_ingredients],
        missing_ingredients: match[:missing_ingredients]
      }
    end

    prompt = <<~PROMPT
      Ești un asistent culinar prietenos pentru aplicația Recipy. 
      
      Utilizatorul are aceste ingrediente: #{parsed_request['ingredients'].join(', ')}
      Preferințe: #{parsed_request['preferences'].to_json}
      
      Am găsit aceste rețete care se potrivesc:
      #{recipes_info.to_json}
      
      Generează un răspuns prietenos în română care:
      1. Recomandă cea mai potrivită rețetă și explică de ce
      2. Menționează ce ingrediente lipsesc (dacă există) și sugerează alternative simple
      3. Oferă 1-2 alternative dacă utilizatorul vrea altceva
      4. Fii concis dar informativ
      
      Răspunde în format JSON:
      {
        "message": "mesajul tău prietenos",
        "recommended_recipe_id": id-ul rețetei recomandate,
        "alternatives": [id-uri ale alternativelor],
        "missing_ingredients_suggestions": ["ingredient1 poate fi înlocuit cu X", etc],
        "type": "recommendation"
      }
    PROMPT

    response = @client.chat(
      parameters: {
        model: OPENAI_MODEL,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")
    result = JSON.parse(content)
    result["matching_recipes"] = recipes_info
    result
  rescue JSON::ParserError, StandardError => e
    Rails.logger.error "Failed to generate recommendation: #{e.message}"
    {
      "message" => "Am găsit #{matching_recipes.length} rețete care se potrivesc cu ingredientele tale! Verifică lista de mai jos.",
      "matching_recipes" => recipes_info,
      "type" => "recommendation"
    }
  end

  def generate_new_recipe_response(parsed_request)
    ingredients = parsed_request["ingredients"]
    preferences = parsed_request["preferences"] || {}

    if ingredients.length < 3
      return generate_insufficient_ingredients_response(ingredients, preferences)
    end

    prompt = <<~PROMPT
      Ești un chef profesionist care creează rețete pentru aplicația Recipy.
      
      Creează o rețetă delicioasă folosind aceste ingrediente: #{ingredients.join(', ')}
      
      Preferințe utilizator:
      - Sănătos: #{preferences['healthy'] ? 'Da' : 'Nu neapărat'}
      - Metodă de gătit: #{preferences['cooking_method'] || 'orice'}
      - Dificultate: #{preferences['difficulty'] || 'orice'}
      - Timp maxim: #{preferences['time_limit_minutes'] ? "#{preferences['time_limit_minutes']} minute" : 'nelimitat'}
      - Bucătărie: #{preferences['cuisine_type'] || 'orice'}
      - Restricții: #{preferences['dietary_restrictions']&.join(', ') || 'niciuna'}
      
      Răspunde în format JSON:
      {
        "message": "un mesaj prietenos de introducere",
        "recipe": {
          "title": "Numele rețetei",
          "description": "Descriere scurtă și apetisantă",
          "ingredients": "Lista completă de ingrediente cu cantități (fiecare pe linie nouă)",
          "preparation": "Pașii de preparare detaliați (numerotați)",
          "time_to_make": număr în minute,
          "difficulty": număr 1-5,
          "healthiness": număr 1-5,
          "tips": "Sfaturi și trucuri opționale"
        },
        "additional_ingredients_needed": ["ingredient1", "ingredient2"],
        "type": "generated_recipe"
      }
    PROMPT

    response = @client.chat(
      parameters: {
        model: OPENAI_MODEL,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.8
      }
    )

    content = response.dig("choices", 0, "message", "content")
    JSON.parse(content)
  rescue JSON::ParserError, StandardError => e
    Rails.logger.error "Failed to generate recipe: #{e.message}"
    {
      "message" => "Îmi pare rău, nu am putut genera o rețetă momentan. Te rog să încerci din nou.",
      "type" => "error"
    }
  end

  def generate_insufficient_ingredients_response(ingredients, preferences)
    prompt = <<~PROMPT
      Ești un asistent culinar prietenos pentru aplicația Recipy.
      
      Utilizatorul are doar aceste ingrediente: #{ingredients.join(', ')}
      
      Sunt prea puține pentru a face o rețetă completă. Sugerează:
      1. Ce ingrediente simple și comune ar trebui să mai cumpere
      2. Ce rețete simple ar putea face cu aceste ingrediente + sugestiile tale
      
      Răspunde în format JSON:
      {
        "message": "mesaj prietenos explicând situația",
        "suggested_ingredients": ["ingredient1", "ingredient2", "ingredient3"],
        "possible_recipes_with_additions": ["idee rețetă 1", "idee rețetă 2"],
        "type": "insufficient_ingredients"
      }
    PROMPT

    response = @client.chat(
      parameters: {
        model: OPENAI_MODEL,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")
    JSON.parse(content)
  rescue JSON::ParserError, StandardError => e
    Rails.logger.error "Failed to generate suggestions: #{e.message}"
    {
      "message" => "Ai doar #{ingredients.length} ingrediente. Pentru o rețetă completă, ai nevoie de cel puțin 3-4 ingrediente. Ce alte ingrediente ai în bucătărie?",
      "type" => "insufficient_ingredients"
    }
  end
end

