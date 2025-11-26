class Admin::AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_admin_locale

  def set_admin_locale
    I18n.locale = I18n.default_locale
  end

  def index
    # Dashboard stats
    @total_users = User.count
    @total_recipes = Recipe.count
    @total_categories = Category.count
    @total_cuisines = Cuisine.count
    @total_food_types = FoodType.count
    @site_setting = SiteSetting.instance
    @themes = Theme.order(:name)

    # Recent activity
    @new_users_today = User.where("created_at >= ?", Time.current.beginning_of_day).count
    @new_recipes_today = Recipe.where("created_at >= ?", Time.current.beginning_of_day).count
    @new_users_week = User.where("created_at >= ?", 1.week.ago).count
    @new_recipes_week = Recipe.where("created_at >= ?", 1.week.ago).count
    @new_users_month = User.where("created_at >= ?", 1.month.ago).count
    @new_recipes_month = Recipe.where("created_at >= ?", 1.month.ago).count
  end

  def settings
    # Force reload to get latest values
    @site_setting = SiteSetting.instance.reload
  end

  def update_settings
    @site_setting = SiteSetting.instance
    if @site_setting.update(site_setting_params)
      # Force reload to clear cache and update CSS variables
      @site_setting.reload
      # Clear Rails cache for site settings
      Rails.cache.delete("site_setting_instance")
      # Clear ActiveRecord query cache
      ActiveRecord::Base.connection.clear_query_cache
      redirect_to admin_settings_path, notice: t("admin.settings.updated")
    else
      render :settings, status: :unprocessable_entity
    end
  end

  def users
    @query = params[:q].to_s.strip
    @users = User.includes(:recipes, :followers, :following)

    if @query.present?
      @users = @users.where("username ILIKE ? OR email ILIKE ?", "%#{@query}%", "%#{@query}%")
    end

    @users = @users.order(created_at: :desc).limit(100)
  end

  def recipes
    @recipes = Recipe.includes(:user, :category, :cuisine, :food_type)
                     .order(created_at: :desc)
                     .limit(100)
  end

  def categories
    @categories = Category.all.order(:name)
  end

  def cuisines
    @cuisines = Cuisine.all.order(:name)
  end

  def food_types
    @food_types = FoodType.all.order(:name)
  end

  def edit_user
    @user = User.find(params[:id])
  end

  def update_user
    @user = User.find(params[:id])

    # Handle password update separately if provided
    if user_params[:password].present?
      if @user.update(user_params)
        redirect_to admin_users_path, notice: t("admin.users.updated")
      else
        render :edit_user, status: :unprocessable_entity
      end
    else
      # Update without password
      update_params = user_params.except(:password, :password_confirmation)
      if @user.update(update_params)
        redirect_to admin_users_path, notice: t("admin.users.updated")
      else
        render :edit_user, status: :unprocessable_entity
      end
    end
  end

  def destroy_recipe
    @recipe = Recipe.find(params[:id])
    @user = @recipe.user
    recipe_title = @recipe.title
    recipe_preview = @recipe.ingredients&.truncate(100) || ""
    recipe_id = @recipe.id

    # Create notification before destroying
    if @user
      Notification.create!(
        user: @user,
        notification_type: "recipe_removed",
        title: t("admin.notifications.recipe_removed_title"),
        message: t("admin.notifications.recipe_removed_message", title: recipe_title, preview: recipe_preview),
        recipe_id: recipe_id
      )
    end

    @recipe.destroy
    redirect_to admin_recipes_path, notice: t("admin.recipes.deleted")
  end

  def reset_password
    @user = User.find(params[:user_id])
    new_password = Devise.friendly_token[0, 12]
    @user.update(password: new_password, password_confirmation: new_password)
    redirect_to admin_users_path, notice: t("admin.users.password_reset", email: @user.email || @user.username, password: new_password)
  end

  def reports
    @period = params[:period] || "week"

    case @period
    when "day"
      start_date = Time.current.beginning_of_day
    when "week"
      start_date = 1.week.ago
    when "month"
      start_date = 1.month.ago
    when "year"
      start_date = 1.year.ago
    else
      start_date = 1.week.ago
    end

    @new_users = User.where("created_at >= ?", start_date).count
    @new_recipes = Recipe.where("created_at >= ?", start_date).count
    @new_comments = Comment.where("created_at >= ?", start_date).count
    @new_likes = Like.where("created_at >= ?", start_date).count
    @new_follows = Follow.where("created_at >= ?", start_date).count
  end

  def export_reports
    @period = params[:period] || "week"

    case @period
    when "day"
      start_date = Time.current.beginning_of_day
    when "week"
      start_date = 1.week.ago
    when "month"
      start_date = 1.month.ago
    when "year"
      start_date = 1.year.ago
    else
      start_date = 1.week.ago
    end

    format = params[:format] || "csv"

    case format
    when "csv", "xlsx"
      export_to_excel(start_date)
    when "pdf"
      export_to_pdf(start_date)
    else
      redirect_to admin_reports_path, alert: t("admin.reports.invalid_format")
    end
  end

  def site_setting_params
    params.require(:site_setting).permit(:contact_email, :contact_phone, :contact_address,
                                         :primary_color, :secondary_color, :accent_color,
                                         :navbar_color, :button_color, :link_color, :background_color,
                                         :card_background, :text_primary, :text_secondary, :border_color,
                                         :success_color, :warning_color, :error_color,
                                         :footer_background, :footer_text, :footer_link, :footer_link_hover)
  end

  def user_params
    # Permit basic user attributes
    permitted = params.require(:user).permit(:username, :email, :password, :password_confirmation)

    # Only allow admin flag modification by verified admins (extra security layer)
    # This prevents mass assignment attacks even if someone bypasses controller auth
    if current_user&.admin? && params[:user].key?(:admin)
      permitted[:admin] = ActiveModel::Type::Boolean.new.cast(params[:user][:admin])
    end

    permitted
  end

  def export_to_excel(start_date)
    # Use CSV format - simple, universal, no dependencies
    require "csv"

    csv_data = CSV.generate(headers: true) do |csv|
      # Header row
      csv << [ t("admin.reports.period"), @period.capitalize ]
      csv << [ t("admin.reports.start_date"), start_date.strftime("%Y-%m-%d") ]
      csv << [] # Empty row

      # Data headers
      csv << [ t("admin.reports.metric"), t("admin.reports.count") ]

      # Data rows
      csv << [ t("admin.reports.new_users"), User.where("created_at >= ?", start_date).count ]
      csv << [ t("admin.reports.new_recipes"), Recipe.where("created_at >= ?", start_date).count ]
      csv << [ t("admin.reports.new_comments"), Comment.where("created_at >= ?", start_date).count ]
      csv << [ t("admin.reports.new_likes"), Like.where("created_at >= ?", start_date).count ]
      csv << [ t("admin.reports.new_follows"), Follow.where("created_at >= ?", start_date).count ]
    end

    send_data csv_data,
              filename: "reports_#{@period}_#{Time.current.strftime('%Y%m%d')}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  def export_to_pdf(start_date)
    # Use Prawn for PDF generation (was working before)
    begin
      Bundler.require(:admin)
      require "prawn"
      require "prawn/table"
    rescue LoadError, ArgumentError => e
      Rails.logger.error "Failed to load prawn: #{e.message}"
      redirect_to admin_reports_path(period: @period), alert: t("admin.reports.export_error")
      return
    end

    # Configure Prawn for UTF-8 support
    pdf = Prawn::Document.new(page_size: "A4", page_layout: :portrait)

    # Helper method to safely encode text for PDF
    # Prawn's default fonts don't support all UTF-8 characters, so we'll use ASCII transliteration
    safe_text = lambda do |text|
      # Convert to ASCII-friendly characters for Romanian text
      text.to_s
          .gsub(/ă/, "a").gsub(/Ă/, "A")
          .gsub(/â/, "a").gsub(/Â/, "A")
          .gsub(/î/, "i").gsub(/Î/, "I")
          .gsub(/ș/, "s").gsub(/Ș/, "S")
          .gsub(/ț/, "t").gsub(/Ț/, "T")
          .force_encoding("UTF-8")
          .encode("UTF-8", invalid: :replace, undef: :replace)
    end

    pdf.text safe_text.call(t("admin.reports.title")), size: 24, style: :bold
    pdf.move_down 10
    pdf.text safe_text.call("#{t('admin.reports.period')}: #{@period.capitalize}"), size: 14
    pdf.text safe_text.call("#{t('admin.reports.start_date')}: #{start_date.strftime('%Y-%m-%d')}"), size: 14
    pdf.move_down 20

    data = [
      [ safe_text.call(t("admin.reports.metric")), safe_text.call(t("admin.reports.count")) ],
      [ safe_text.call(t("admin.reports.new_users")), User.where("created_at >= ?", start_date).count.to_s ],
      [ safe_text.call(t("admin.reports.new_recipes")), Recipe.where("created_at >= ?", start_date).count.to_s ],
      [ safe_text.call(t("admin.reports.new_comments")), Comment.where("created_at >= ?", start_date).count.to_s ],
      [ safe_text.call(t("admin.reports.new_likes")), Like.where("created_at >= ?", start_date).count.to_s ],
      [ safe_text.call(t("admin.reports.new_follows")), Follow.where("created_at >= ?", start_date).count.to_s ]
    ]

    begin
      pdf.table(data, header: true, width: pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = "E0E0E0"
      end
    rescue => e
      Rails.logger.error "Error creating PDF table: #{e.message}"
      pdf.text "Error generating table: #{e.message}", size: 12
    end

    # Render PDF and send it
    begin
      pdf_data = pdf.render

      # Verify PDF data is valid (should start with %PDF)
      unless pdf_data.is_a?(String) && pdf_data.length > 0 && pdf_data.start_with?("%PDF")
        Rails.logger.error "Invalid PDF data generated"
        redirect_to admin_reports_path(period: @period), alert: t("admin.reports.export_error")
        return
      end
    rescue => e
      Rails.logger.error "Error rendering PDF: #{e.message}"
      redirect_to admin_reports_path(period: @period), alert: t("admin.reports.export_error")
      return
    end

    # Send the PDF data with proper headers
    send_data pdf_data,
              filename: "reports_#{@period}_#{Time.current.strftime('%Y%m%d')}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  # Legal Pages Management
  def legal_contents
    @pages = LegalPage.all_pages
    @selected_page = params[:page]

    if @selected_page.present? && LegalPage::PAGES.include?(@selected_page)
      @legal_page = LegalPage.find_or_initialize(@selected_page)
    end
  end

  def edit_legal_page
    @page_type = params[:page_type]
    unless LegalPage::PAGES.include?(@page_type)
      redirect_to admin_legal_contents_path, alert: "Invalid page type"
      return
    end

    @legal_page = LegalPage.find_or_initialize(@page_type)
    @page_title = LegalPage.page_title(@page_type)
    @page_color = LegalPage.page_color(@page_type)

    # Load current YAML content as default if database is empty
    if @legal_page.full_content_ro.blank?
      @legal_page.full_content_ro = load_yaml_content(@page_type, :ro)
    end
    if @legal_page.full_content_en.blank?
      @legal_page.full_content_en = load_yaml_content(@page_type, :en)
    end
  end

  def update_legal_page
    @page_type = params[:page_type]
    unless LegalPage::PAGES.include?(@page_type)
      redirect_to admin_legal_contents_path, alert: "Invalid page type"
      return
    end

    @legal_page = LegalPage.find_or_initialize(@page_type)
    @legal_page.key = "page_#{@page_type}"
    @legal_page.page_type = @page_type
    @legal_page.title_ro = LegalPage.page_title(@page_type)
    @legal_page.title_en = LegalPage.page_title(@page_type)
    @legal_page.active = true
    @legal_page.full_content_ro = params[:legal_page][:full_content_ro]
    @legal_page.full_content_en = params[:legal_page][:full_content_en]

    if @legal_page.save
      redirect_to admin_legal_contents_path(page: @page_type), notice: "#{LegalPage.page_title(@page_type)} saved successfully!"
    else
      @page_title = LegalPage.page_title(@page_type)
      @page_color = LegalPage.page_color(@page_type)
      render :edit_legal_page, status: :unprocessable_entity
    end
  end

  def themes
    @themes = Theme.all.order(:name)
  end

  def edit_theme
    @theme = Theme.find(params[:id])
  end

  def update_theme
    @theme = Theme.find(params[:id])
    if @theme.update(theme_params)
      redirect_to admin_themes_path, notice: t("admin.themes.updated")
    else
      render :edit_theme, status: :unprocessable_entity
    end
  end

  def new_theme
    @theme = Theme.new
  end

  def create_theme
    @theme = Theme.new(theme_params)
    if @theme.save
      redirect_to admin_themes_path, notice: t("admin.themes.created")
    else
      render :new_theme, status: :unprocessable_entity
    end
  end

  def set_default_theme
    @theme = Theme.find(params[:id])
    Theme.update_all(is_default: false)
    @theme.update(is_default: true)
    redirect_to admin_themes_path, notice: t("admin.themes.set_default")
  end

  def reset_password
    @user = User.find(params[:user_id])
    new_password = Devise.friendly_token[0, 12]
    @user.update(password: new_password, password_confirmation: new_password)
    redirect_to admin_users_path, notice: t("admin.users.password_reset", email: @user.email || @user.username, password: new_password)
  end

  def change_user_email
    @user = User.find(params[:user_id])
    new_email = params[:new_email]
    if new_email.present? && @user.update(email: new_email)
      redirect_to admin_users_path, notice: t("admin.users.email_changed", email: new_email)
    else
      redirect_to admin_users_path, alert: t("admin.users.email_change_failed")
    end
  end

  private

  def ensure_admin
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.unauthorized")
    end
  end

  def theme_params
    params.require(:theme).permit(:name, :primary_color, :secondary_color, :accent_color,
                                   :navbar_color, :button_color, :link_color, :background_color,
                                   :card_background, :text_primary, :text_secondary, :border_color,
                                   :success_color, :warning_color, :error_color, :is_default)
  end

  def legal_content_params
    params.require(:legal_content).permit(:key, :title_ro, :title_en, :content_ro, :content_en, :section_order, :active)
  end

  def load_yaml_content(page_type, locale)
    # Build content from YAML translations
    translations = I18n.t("legal.#{page_type}", locale: locale, default: {})
    return "" unless translations.is_a?(Hash)

    content = []
    content << "# #{translations[:title]}\n" if translations[:title]
    content << "#{translations[:intro]}\n\n" if translations[:intro]

    translations.each do |key, value|
      next if [ :title, :intro ].include?(key)
      next unless value.is_a?(Hash)

      content << "## #{value[:title]}\n" if value[:title]

      if value[:content]
        content << "#{value[:content]}\n\n"
      else
        # Handle p1, p2, p3 format
        (1..10).each do |i|
          para = value[:"p#{i}"]
          content << "#{para}\n\n" if para
        end
      end
    end

    content.join
  end
end
