class LiveSessionsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_live_session, only: [:show, :update, :destroy, :start, :end]
  before_action :authorize_owner, only: [:update, :destroy, :start, :end]

  def index
    @upcoming_sessions = LiveSession.upcoming.includes(:user, :recipe)
    @live_now = LiveSession.live_now.includes(:user, :recipe)
    @past_sessions = LiveSession.past.limit(20).includes(:user, :recipe)
  end

  def show
    @live_session.increment_viewer_count! if @live_session.live?
  end

  def new
    @live_session = current_user.live_sessions.build
    @recipes = current_user.recipes.order(created_at: :desc).limit(50)
  end

  def create
    @live_session = current_user.live_sessions.build(live_session_params)
    
    if @live_session.save
      redirect_to live_session_path(@live_session, locale: I18n.locale), notice: t('live_sessions.created_successfully')
    else
      @recipes = current_user.recipes.order(created_at: :desc).limit(50)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @live_session.update(live_session_params)
      redirect_to live_session_path(@live_session, locale: I18n.locale), notice: t('live_sessions.updated_successfully')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @live_session.destroy
    redirect_to live_sessions_path(locale: I18n.locale), notice: t('live_sessions.deleted_successfully')
  end

  def start
    @live_session.start!
    redirect_to live_session_path(@live_session, locale: I18n.locale), notice: t('live_sessions.started')
  end

  def end
    @live_session.end!
    redirect_to live_sessions_path(locale: I18n.locale), notice: t('live_sessions.ended')
  end

  private

  def set_live_session
    @live_session = LiveSession.find(params[:id])
  end

  def authorize_owner
    unless @live_session.user == current_user || current_user.admin?
      redirect_to live_sessions_path(locale: I18n.locale), alert: t('errors.unauthorized')
    end
  end

  def live_session_params
    params.require(:live_session).permit(:title, :description, :scheduled_at, :recipe_id, :stream_url)
  end
end
