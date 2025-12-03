# frozen_string_literal: true

class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:webhook]
  before_action :authenticate_user!, except: [:webhook]

  # POST /stripe/create-checkout-session
  # Create a Stripe Checkout Session for subscription
  def create_checkout_session
    # Get price ID from params or environment variable
    price_id = params[:priceId] || ENV['STRIPE_PRICE_ID_AI_CHAT']
    
    Rails.logger.info "Creating checkout session with price_id: #{price_id.inspect}"
    Rails.logger.info "ENV['STRIPE_PRICE_ID_AI_CHAT']: #{ENV['STRIPE_PRICE_ID_AI_CHAT'].inspect}"
    
    if price_id.blank?
      Rails.logger.error "STRIPE_PRICE_ID_AI_CHAT is not set in environment variables"
      render json: { error: "Price ID not configured. Please contact support." }, status: :internal_server_error
      return
    end

    begin
      locale = I18n.locale.to_s
      base_url = request.base_url
      
      # Verify Stripe API key is set
      if Stripe.api_key.blank?
        Rails.logger.error "Stripe API key is not set!"
        render json: { error: "Stripe configuration error. Please contact support." }, status: :internal_server_error
        return
      end
      
      Rails.logger.info "Using Stripe API key: #{Stripe.api_key[0..10]}..."
      Rails.logger.info "Creating checkout with price_id: #{price_id}"
      
      session = Stripe::Checkout::Session.create({
        customer_email: current_user.email,
        client_reference_id: current_user.id.to_s,
        success_url: "#{base_url}/#{locale}/stripe/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{base_url}/#{locale}/stripe/cancel",
        mode: 'subscription',
        line_items: [{
          quantity: 1,
          price: price_id
        }],
        subscription_data: {
          metadata: {
            user_id: current_user.id.to_s,
            plan_type: Subscription::PLAN_AI_CHAT
          }
        }
      })

      render json: { sessionId: session.id, url: session.url }
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Stripe InvalidRequestError: #{e.message}"
      Rails.logger.error "Price ID used: #{price_id}"
      Rails.logger.error "API Key prefix: #{Stripe.api_key[0..10] if Stripe.api_key.present?}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      render json: { error: "Price ID invalid or not found. Please contact support." }, status: :unprocessable_entity
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      Rails.logger.error "Price ID used: #{price_id}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "General error in create_checkout_session: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      render json: { error: "A apărut o eroare. Te rugăm să încerci din nou." }, status: :internal_server_error
    end
  end

  # GET /stripe/success
  # Handle successful payment
  def success
    session_id = params[:session_id]

    if session_id.blank?
      redirect_to root_path, alert: "Sesiune invalidă."
      return
    end

    begin
      session = Stripe::Checkout::Session.retrieve(session_id)
      
      if session.payment_status == 'paid'
        # Try to create subscription if webhook hasn't processed it yet
        user_id = session.client_reference_id || session.subscription_data&.metadata&.user_id
        
        if user_id && current_user.id.to_s == user_id.to_s
          # Check if subscription already exists
          subscription_id = session.subscription
          
          if subscription_id
            existing_subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
            
            unless existing_subscription
              # Webhook hasn't processed it yet, create it manually
              begin
                stripe_subscription = Stripe::Subscription.retrieve(subscription_id)
                create_or_update_subscription(current_user, stripe_subscription)
                Rails.logger.info "Created subscription manually in success action: #{subscription_id}"
              rescue => e
                Rails.logger.error "Failed to create subscription manually: #{e.message}"
                # Continue anyway - webhook will process it
              end
            end
          end
        end
        
        redirect_to ai_assistant_path, notice: "Abonamentul a fost activat cu succes! Acum poți folosi OpenAI în chat."
      else
        redirect_to root_path, alert: "Plata nu a fost finalizată."
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error in success: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      redirect_to root_path, alert: "A apărut o eroare: #{e.message}"
    rescue => e
      Rails.logger.error "General error in success: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      redirect_to root_path, alert: "A apărut o eroare neașteptată."
    end
  end

  # GET /stripe/cancel
  # Handle canceled payment
  def cancel
    redirect_to ai_assistant_path, alert: "Plata a fost anulată."
  end

  # POST /stripe/webhook
  # Handle Stripe webhook events
  def webhook
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.configuration.stripe[:webhook_secret]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid payload: #{e.message}"
      render json: { error: "Invalid payload" }, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Invalid signature: #{e.message}"
      render json: { error: "Invalid signature" }, status: :bad_request
      return
    end

    # Handle the event
    case event.type
    when 'checkout.session.completed'
      handle_checkout_session_completed(event.data.object)
    when 'customer.subscription.created', 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event.data.object)
    when 'invoice.payment_succeeded'
      handle_invoice_payment_succeeded(event.data.object)
    when 'invoice.payment_failed'
      handle_invoice_payment_failed(event.data.object)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    render json: { received: true }
  end

  private

  def handle_checkout_session_completed(session)
    user_id = session.client_reference_id || session.subscription_data&.metadata&.user_id
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user

    # Retrieve subscription from Stripe
    subscription_id = session.subscription
    return unless subscription_id

    subscription = Stripe::Subscription.retrieve(subscription_id)
    create_or_update_subscription(user, subscription)
  end

  def handle_subscription_updated(stripe_subscription)
    user_id = stripe_subscription.metadata&.user_id
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user

    create_or_update_subscription(user, stripe_subscription)
  end

  def handle_subscription_deleted(stripe_subscription)
    subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
    return unless subscription

    subscription.update(
      status: Subscription::STATUS_CANCELED,
      canceled_at: Time.current
    )
  end

  def handle_invoice_payment_succeeded(invoice)
    subscription_id = invoice.subscription
    return unless subscription_id

    subscription = Stripe::Subscription.retrieve(subscription_id)
    user_id = subscription.metadata&.user_id
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user

    create_or_update_subscription(user, subscription)
  end

  def handle_invoice_payment_failed(invoice)
    subscription_id = invoice.subscription
    return unless subscription_id

    subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
    return unless subscription

    subscription.update(status: Subscription::STATUS_PAST_DUE)
  end

  def create_or_update_subscription(user, stripe_subscription)
    plan_type = stripe_subscription.metadata&.plan_type || Subscription::PLAN_AI_CHAT

    subscription = Subscription.find_or_initialize_by(
      stripe_subscription_id: stripe_subscription.id
    )

    # For flexible billing, period is in items.data[0]
    # For regular subscriptions, period is directly on subscription
    period_start = nil
    period_end = nil
    
    if stripe_subscription.respond_to?(:current_period_start) && stripe_subscription.current_period_start
      period_start = Time.at(stripe_subscription.current_period_start)
      period_end = Time.at(stripe_subscription.current_period_end)
    elsif stripe_subscription.items && stripe_subscription.items.data.any?
      # Flexible billing mode - get period from first item
      first_item = stripe_subscription.items.data.first
      if first_item.respond_to?(:current_period_start) && first_item.current_period_start
        period_start = Time.at(first_item.current_period_start)
        period_end = Time.at(first_item.current_period_end)
      end
    end
    
    # Fallback to created date if no period found
    period_start ||= Time.at(stripe_subscription.created)
    period_end ||= period_start + 1.month

    subscription.assign_attributes(
      user: user,
      status: stripe_subscription.status,
      plan_type: plan_type,
      current_period_start: period_start,
      current_period_end: period_end,
      canceled_at: stripe_subscription.canceled_at ? Time.at(stripe_subscription.canceled_at) : nil
    )

    subscription.save!
  end
end

