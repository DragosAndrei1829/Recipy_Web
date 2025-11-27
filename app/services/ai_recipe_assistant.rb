# frozen_string_literal: true

# AI Recipe Assistant Service - 3-Tier System
# Tier 1: Local search (FREE) - Search existing recipes without AI
# Tier 2: Llama/Ollama (FREE) - Generate recipes with local AI
# Tier 3: OpenAI (PAID) - Premium AI generation (optional)
class AiRecipeAssistant
  MAX_RECIPE_MATCHES = 5
  MIN_INGREDIENT_MATCH_PERCENTAGE = 0.4 # 40% match threshold

  # AI Provider options
  PROVIDER_LOCAL = "local"      # No AI, just search
  PROVIDER_LLAMA = "llama"      # Free Ollama/Llama
  PROVIDER_OPENAI = "openai"    # Paid OpenAI

  # Common Romanian ingredients dictionary for parsing
  INGREDIENT_KEYWORDS = %w[
    pui carne vită porc miel pește somon ton creveți
    cartofi roșii tomate ceapă usturoi morcovi ardei vinete dovlecei 
    broccoli conopidă varză spanac salată castraveți
    brânză cașcaval telemea parmezan mozzarella ricotta
    lapte smântână frișcă unt iaurt ouă ou
    paste spaghete macaroane orez quinoa couscous
    făină pâine pesmet griș mălai
    ulei măsline unt untură
    sare piper boia oregano busuioc cimbru rozmarin pătrunjel mărar
    zahăr miere ciocolată cacao vanilie
    lămâie portocale mere pere banane căpșuni
    vin bere oțet zeamă bulion sos
    nucă migdale alune susan mac
    fasole mazăre linte năut ciuperci
  ].freeze

  # Preference keywords
  HEALTHY_KEYWORDS = %w[sănătos sănătoasă light dietetic fit slăbit].freeze
  QUICK_KEYWORDS = %w[rapid repede minute simplu ușor grăbit].freeze
  OVEN_KEYWORDS = %w[cuptor copt la\ cuptor gratina].freeze
  PAN_KEYWORDS = %w[tigaie prăjit soteu wok].freeze
  BOIL_KEYWORDS = %w[fiert fierbere abur].freeze
  VEGETARIAN_KEYWORDS = %w[vegetarian veggie fără\ carne legume].freeze
  VEGAN_KEYWORDS = %w[vegan vegetal fără\ lactate].freeze

  def initialize(user: nil, provider: PROVIDER_LOCAL)
    @user = user
    @provider = provider
    @ollama_url = ENV.fetch("OLLAMA_URL", "http://localhost:11434")
  end

  # Main entry point - process user message and return response
  def chat(message, conversation_history: [], force_provider: nil)
    provider = force_provider || @provider

    # Step 1: Parse ingredients locally (FREE - no AI needed)
    parsed_request = parse_user_request_locally(message)

    # Step 2: Search existing recipes (FREE - no AI needed)
    matching_recipes = find_matching_recipes(parsed_request)

    # Step 3: Generate response based on results
    if matching_recipes.any?
      # Found matches - return them with local formatting (FREE)
      generate_local_recommendation_response(parsed_request, matching_recipes)
    else
      # No matches - use AI to generate recipe
      case provider
      when PROVIDER_OPENAI
        generate_recipe_with_openai(parsed_request)
      when PROVIDER_LLAMA
        generate_recipe_with_llama(parsed_request)
      else
        # Local only - suggest what to do
        generate_no_match_local_response(parsed_request)
      end
    end
  end

  # Check which AI providers are available
  def self.available_providers
    providers = [PROVIDER_LOCAL] # Always available

    # Check Ollama
    if ollama_available?
      providers << PROVIDER_LLAMA
    end

    # Check OpenAI
    if ENV["OPENAI_API_KEY"].present?
      providers << PROVIDER_OPENAI
    end

    providers
  end

  def self.ollama_available?
    require "net/http"
    uri = URI(ENV.fetch("OLLAMA_URL", "http://localhost:11434") + "/api/tags")
    response = Net::HTTP.get_response(uri)
    response.is_a?(Net::HTTPSuccess)
  rescue StandardError
    false
  end

  private

  # ============================================
  # TIER 1: LOCAL PARSING & SEARCH (FREE)
  # ============================================

  def parse_user_request_locally(message)
    message_lower = message.downcase

    # Extract ingredients using keyword matching
    ingredients = extract_ingredients_locally(message_lower)

    # Detect preferences from keywords
    preferences = detect_preferences_locally(message_lower)

    {
      "ingredients" => ingredients,
      "preferences" => preferences,
      "original_message" => message
    }
  end

  def extract_ingredients_locally(message)
    found_ingredients = []

    # Check for known ingredients
    INGREDIENT_KEYWORDS.each do |ingredient|
      if message.include?(ingredient)
        found_ingredients << ingredient
      end
    end

    # Also extract words that look like ingredients (nouns after "am", "cu", etc.)
    # Pattern: "am X", "cu X", "și X"
    message.scan(/(?:am|cu|și|plus|adaug)\s+(\w+)/i).flatten.each do |word|
      word = word.downcase.strip
      if word.length > 2 && !%w[un o pe la de în].include?(word)
        found_ingredients << word unless found_ingredients.include?(word)
      end
    end

    found_ingredients.uniq
  end

  def detect_preferences_locally(message)
    preferences = {}

    # Healthy
    preferences["healthy"] = HEALTHY_KEYWORDS.any? { |kw| message.include?(kw) }

    # Cooking method
    if OVEN_KEYWORDS.any? { |kw| message.include?(kw) }
      preferences["cooking_method"] = "cuptor"
    elsif PAN_KEYWORDS.any? { |kw| message.include?(kw) }
      preferences["cooking_method"] = "tigaie"
    elsif BOIL_KEYWORDS.any? { |kw| message.include?(kw) }
      preferences["cooking_method"] = "fiert"
    end

    # Time limit
    if match = message.match(/(\d+)\s*(?:min|minute)/)
      preferences["time_limit_minutes"] = match[1].to_i
    elsif QUICK_KEYWORDS.any? { |kw| message.include?(kw) }
      preferences["time_limit_minutes"] = 30
    end

    # Dietary restrictions
    restrictions = []
    restrictions << "vegetarian" if VEGETARIAN_KEYWORDS.any? { |kw| message.include?(kw) }
    restrictions << "vegan" if VEGAN_KEYWORDS.any? { |kw| message.include?(kw) }
    preferences["dietary_restrictions"] = restrictions if restrictions.any?

    # Difficulty
    if message.include?("ușor") || message.include?("simplu")
      preferences["difficulty"] = "ușor"
    elsif message.include?("greu") || message.include?("complex")
      preferences["difficulty"] = "greu"
    end

    preferences
  end

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
    if preferences["healthy"]
      recipes = recipes.where("healthiness >= ?", 3)
    end

    case preferences["difficulty"]
    when "ușor"
      recipes = recipes.where("difficulty <= ?", 2)
    when "mediu"
      recipes = recipes.where("difficulty BETWEEN ? AND ?", 2, 4)
    when "greu"
      recipes = recipes.where("difficulty >= ?", 4)
    end

    if preferences["time_limit_minutes"].present?
      recipes = recipes.where("time_to_make <= ?", preferences["time_limit_minutes"])
    end

    if preferences["cuisine_type"].present?
      cuisine = Cuisine.find_by("LOWER(name) LIKE ?", "%#{preferences['cuisine_type'].downcase}%")
      recipes = recipes.where(cuisine: cuisine) if cuisine
    end

    # Filter by dietary restrictions
    if preferences["dietary_restrictions"]&.include?("vegetarian")
      # Exclude recipes with meat keywords
      meat_keywords = %w[pui carne vită porc miel pește]
      recipes = recipes.where.not("LOWER(ingredients) SIMILAR TO ?", "%(#{meat_keywords.join('|')})%")
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

    recipe_ing.include?(user_ing) ||
      user_ing.include?(recipe_ing) ||
      similar_ingredients?(user_ing, recipe_ing)
  end

  def similar_ingredients?(ing1, ing2)
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

  # Generate response when recipes are found (NO AI - FREE)
  def generate_local_recommendation_response(parsed_request, matching_recipes)
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

    best_match = recipes_info.first
    ingredients_list = parsed_request["ingredients"].join(", ")

    message = "🎉 Am găsit #{matching_recipes.length} rețet#{matching_recipes.length == 1 ? 'ă' : 'e'} care se potrivesc cu ingredientele tale (#{ingredients_list})!\n\n"
    message += "📌 **Recomandarea mea:** #{best_match[:title]} - #{best_match[:match_percentage]}% potrivire"

    if best_match[:missing_ingredients].any?
      message += "\n\n⚠️ Ingrediente care îți lipsesc: #{best_match[:missing_ingredients].first(3).join(', ')}"
    end

    {
      "message" => message,
      "type" => "recommendation",
      "recommended_recipe_id" => best_match[:id],
      "alternatives" => recipes_info[1..3]&.map { |r| r[:id] } || [],
      "matching_recipes" => recipes_info,
      "ai_provider" => "local"
    }
  end

  # Response when no matches found and no AI available
  def generate_no_match_local_response(parsed_request)
    ingredients = parsed_request["ingredients"]

    if ingredients.empty?
      {
        "message" => "🤔 Nu am reușit să identific ingredientele din mesajul tău. Încearcă să le listezi mai clar, de exemplu: \"Am pui, roșii și usturoi\"",
        "type" => "need_clarification",
        "ai_provider" => "local"
      }
    elsif ingredients.length < 3
      {
        "message" => "📝 Ai menționat doar #{ingredients.length} ingredient#{ingredients.length == 1 ? '' : 'e'} (#{ingredients.join(', ')}). Pentru o rețetă completă, ai nevoie de cel puțin 3-4 ingrediente.\n\n💡 **Sugestii:** Adaugă legume (ceapă, morcovi), condimente sau o sursă de proteine.",
        "type" => "insufficient_ingredients",
        "suggested_ingredients" => suggest_complementary_ingredients(ingredients),
        "possible_recipes_with_additions" => suggest_recipe_ideas(ingredients),
        "ai_provider" => "local"
      }
    else
      {
        "message" => "😕 Nu am găsit rețete în baza noastră de date care să se potrivească cu: #{ingredients.join(', ')}.\n\n🤖 **Vrei să generez o rețetă nouă?** Activează AI-ul (Llama gratuit sau OpenAI premium) pentru a crea o rețetă personalizată.",
        "type" => "no_match",
        "ingredients" => ingredients,
        "can_generate" => true,
        "ai_provider" => "local"
      }
    end
  end

  def suggest_complementary_ingredients(ingredients)
    suggestions = []

    # Base suggestions
    base_suggestions = %w[ceapă usturoi ulei sare piper]

    # Protein suggestions if none present
    proteins = %w[pui carne vită porc pește ouă]
    unless ingredients.any? { |i| proteins.any? { |p| i.include?(p) } }
      suggestions << "pui sau ouă (pentru proteine)"
    end

    # Vegetable suggestions
    veggies = %w[roșii morcovi ardei cartofi]
    unless ingredients.any? { |i| veggies.any? { |v| i.include?(v) } }
      suggestions << "roșii sau morcovi (pentru legume)"
    end

    suggestions + base_suggestions.first(3)
  end

  def suggest_recipe_ideas(ingredients)
    ideas = []

    if ingredients.any? { |i| i.include?("pui") }
      ideas << "Pui la tigaie cu legume"
      ideas << "Piept de pui la cuptor"
    end

    if ingredients.any? { |i| i.include?("paste") || i.include?("spaghete") }
      ideas << "Paste cu sos de roșii"
      ideas << "Spaghete aglio e olio"
    end

    if ingredients.any? { |i| i.include?("ou") || i.include?("ouă") }
      ideas << "Omletă cu legume"
      ideas << "Ouă ochiuri cu brânză"
    end

    if ingredients.any? { |i| i.include?("cartof") }
      ideas << "Cartofi la cuptor"
      ideas << "Piure de cartofi"
    end

    ideas.any? ? ideas.first(3) : ["Supă de legume", "Salată mixtă", "Tocăniță simplă"]
  end

  # ============================================
  # TIER 2: LLAMA/OLLAMA (FREE)
  # ============================================

  def generate_recipe_with_llama(parsed_request)
    ingredients = parsed_request["ingredients"]
    preferences = parsed_request["preferences"] || {}

    if ingredients.length < 3
      return generate_no_match_local_response(parsed_request)
    end

    prompt = build_recipe_generation_prompt(ingredients, preferences)

    begin
      response = call_ollama(prompt)
      parse_ai_recipe_response(response, "llama")
    rescue StandardError => e
      Rails.logger.error "Llama generation failed: #{e.message}"
      {
        "message" => "⚠️ Serviciul AI local (Llama) nu este disponibil momentan. Verifică că Ollama rulează pe #{@ollama_url}",
        "type" => "error",
        "ai_provider" => "llama",
        "error" => e.message
      }
    end
  end

  def call_ollama(prompt)
    require "net/http"
    require "json"

    uri = URI("#{@ollama_url}/api/generate")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 120 # Llama can be slow

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      model: ENV.fetch("OLLAMA_MODEL", "llama3.1:8b"),
      prompt: prompt,
      stream: false,
      options: {
        temperature: 0.7,
        num_predict: 1500
      }
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Ollama returned #{response.code}: #{response.body}"
    end

    JSON.parse(response.body)["response"]
  end

  # ============================================
  # TIER 3: OPENAI (PAID - OPTIONAL)
  # ============================================

  def generate_recipe_with_openai(parsed_request)
    ingredients = parsed_request["ingredients"]
    preferences = parsed_request["preferences"] || {}

    unless ENV["OPENAI_API_KEY"].present?
      return {
        "message" => "⚠️ OpenAI nu este configurat. Adaugă OPENAI_API_KEY în setări sau folosește Llama (gratuit).",
        "type" => "error",
        "ai_provider" => "openai"
      }
    end

    if ingredients.length < 3
      return generate_no_match_local_response(parsed_request)
    end

    prompt = build_recipe_generation_prompt(ingredients, preferences)

    begin
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.7
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_ai_recipe_response(content, "openai")
    rescue StandardError => e
      Rails.logger.error "OpenAI generation failed: #{e.message}"
      {
        "message" => "⚠️ Eroare la generarea rețetei cu OpenAI: #{e.message}",
        "type" => "error",
        "ai_provider" => "openai"
      }
    end
  end

  # ============================================
  # SHARED AI HELPERS
  # ============================================

  def build_recipe_generation_prompt(ingredients, preferences)
    <<~PROMPT
      Ești un chef profesionist care creează rețete în limba română.
      
      Creează o rețetă delicioasă folosind ACESTE ingrediente principale: #{ingredients.join(', ')}
      
      Preferințe:
      - Sănătos: #{preferences['healthy'] ? 'Da' : 'Nu neapărat'}
      - Metodă de gătit: #{preferences['cooking_method'] || 'orice'}
      - Timp maxim: #{preferences['time_limit_minutes'] ? "#{preferences['time_limit_minutes']} minute" : 'nelimitat'}
      - Restricții: #{preferences['dietary_restrictions']&.join(', ') || 'niciuna'}
      
      IMPORTANT: Răspunde DOAR în format JSON valid (fără markdown, fără ```):
      {
        "title": "Numele rețetei",
        "description": "Descriere scurtă",
        "ingredients": "Lista ingrediente cu cantități, fiecare pe linie nouă",
        "preparation": "Pașii de preparare numerotați",
        "time_to_make": numar_minute,
        "difficulty": numar_1_la_5,
        "healthiness": numar_1_la_5,
        "tips": "Sfaturi opționale"
      }
    PROMPT
  end

  def parse_ai_recipe_response(content, provider)
    # Try to extract JSON from response
    json_match = content.match(/\{[\s\S]*\}/)
    raise "No JSON found in response" unless json_match

    recipe_data = JSON.parse(json_match[0])

    {
      "message" => "🍳 Am creat o rețetă specială pentru tine!",
      "type" => "generated_recipe",
      "recipe" => {
        "title" => recipe_data["title"],
        "description" => recipe_data["description"],
        "ingredients" => recipe_data["ingredients"],
        "preparation" => recipe_data["preparation"],
        "time_to_make" => recipe_data["time_to_make"].to_i,
        "difficulty" => recipe_data["difficulty"].to_i,
        "healthiness" => recipe_data["healthiness"].to_i,
        "tips" => recipe_data["tips"]
      },
      "additional_ingredients_needed" => [],
      "ai_provider" => provider
    }
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse AI response: #{e.message}"
    Rails.logger.error "Raw response: #{content}"
    {
      "message" => "⚠️ Am generat o rețetă dar nu am putut-o formata corect. Încearcă din nou.",
      "type" => "error",
      "ai_provider" => provider,
      "raw_response" => content
    }
  end
end
