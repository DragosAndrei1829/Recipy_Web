class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :search, :purchases ]

  def show
    @user = User.find_by(slug: params[:id]) || User.find(params[:id])
    @recipes = @user.recipes.includes(:category, :cuisine, :food_type, photos_attachments: :blob)
                    .order(created_at: :desc)
    @collections = @user.collections.includes(:recipes).recent.limit(6)
    @is_following = user_signed_in? && current_user.following.include?(@user)
  end

  def followers
    @user = User.find_by(slug: params[:id]) || User.find(params[:id])
    @followers = @user.followers.includes(:avatar_attachment)

    # Only allow viewing followers list if it's the current user's profile
    unless user_signed_in? && current_user == @user
      redirect_to user_path(@user), alert: t("follows.cannot_view_followers")
    end
  end

  def search
    @query = params[:q].to_s.strip
    if @query.present?
      @users = User.where("username ILIKE ? OR email ILIKE ?", "%#{@query}%", "%#{@query}%")
                   .limit(10)
    else
      @users = []
    end

    respond_to do |format|
      format.html { render partial: "users/search_results", locals: { users: @users, query: @query } }
      format.json { render json: @users.map { |u| { id: u.id, username: u.username, avatar_url: u.avatar.attached? ? url_for(u.avatar.variant(resize_to_fill: [ 40, 40 ])) : nil } } }
    end
  rescue => e
    respond_to do |format|
      format.html { render partial: "users/search_results", locals: { users: [], query: @query } }
      format.json { render json: [] }
    end
  end

  def purchases
    @user = current_user
    @purchases = []
    
    begin
      # Get all subscriptions for the user
      @subscriptions = @user.subscriptions.order(created_at: :desc)
      
      # Get invoices from Stripe for each subscription
      @subscriptions.each do |subscription|
        begin
          stripe_subscription = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
          
          # Get invoices for this subscription
          invoices = Stripe::Invoice.list(
            subscription: subscription.stripe_subscription_id,
            limit: 100
          )
          
          invoices.data.each do |invoice|
            @purchases << {
              id: invoice.id,
              type: 'subscription',
              amount: invoice.amount_paid / 100.0,
              currency: invoice.currency.upcase,
              status: invoice.status,
              date: Time.at(invoice.created),
              description: "Abonament #{subscription.plan_type == Subscription::PLAN_AI_CHAT ? 'AI Chat' : subscription.plan_type}",
              subscription_id: subscription.stripe_subscription_id,
              livemode: invoice.livemode,
              invoice_pdf: invoice.invoice_pdf,
              hosted_invoice_url: invoice.hosted_invoice_url
            }
          end
        rescue Stripe::StripeError => e
          Rails.logger.error "Error fetching Stripe subscription #{subscription.stripe_subscription_id}: #{e.message}"
        end
      end
      
      # Sort by date (newest first)
      @purchases.sort_by! { |p| p[:date] }.reverse!
      
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error in purchases: #{e.message}"
      @error = "Eroare la încărcarea tranzacțiilor: #{e.message}"
    rescue => e
      Rails.logger.error "General error in purchases: #{e.message}"
      @error = "A apărut o eroare neașteptată."
    end
  end

  def change_theme
    unless user_signed_in?
      redirect_to root_path, alert: t("users.must_be_logged_in")
      return
    end

    theme = Theme.find(params[:theme_id])
    current_user.update(theme: theme)
    # Force a full page reload to apply new CSS variables
    redirect_to request.referer || root_path, notice: t("users.theme_changed", theme: theme.name)
  end
end
