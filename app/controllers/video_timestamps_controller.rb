class VideoTimestampsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe
  before_action :set_video_timestamp, only: [:update, :destroy]
  before_action :authorize_recipe_owner, only: [:create, :update, :destroy]

  def create
    @video_timestamp = @recipe.video_timestamps.build(video_timestamp_params)
    
    if @video_timestamp.save
      respond_to do |format|
        format.turbo_stream
        format.json { render json: @video_timestamp, status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace('timestamp-errors', partial: 'shared/errors', locals: { object: @video_timestamp }) }
        format.json { render json: { errors: @video_timestamp.errors }, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @video_timestamp.update(video_timestamp_params)
      respond_to do |format|
        format.turbo_stream
        format.json { render json: @video_timestamp }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace('timestamp-errors', partial: 'shared/errors', locals: { object: @video_timestamp }) }
        format.json { render json: { errors: @video_timestamp.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @video_timestamp.destroy
    respond_to do |format|
      format.turbo_stream
      format.json { head :no_content }
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find_by(slug: params[:recipe_id]) || Recipe.find(params[:recipe_id])
  end

  def set_video_timestamp
    @video_timestamp = @recipe.video_timestamps.find(params[:id])
  end

  def authorize_recipe_owner
    unless @recipe.user == current_user || current_user.admin?
      redirect_to recipe_path(@recipe, locale: I18n.locale), alert: t('errors.unauthorized')
    end
  end

  def video_timestamp_params
    params.require(:video_timestamp).permit(:step_number, :timestamp_seconds, :title, :description, :position)
  end
end
