class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    @follow = current_user.follows.build(user: @user)

    if @follow.save
      # Reload associations to reflect changes
      current_user.following.reload
      @user.followers.reload

      respond_to do |format|
        format.html { redirect_to user_path(@user), notice: t("follows.followed") }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to user_path(@user), alert: @follow.errors.full_messages.join(", ") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("follow-button-#{@user.id}", partial: "follows/button", locals: { user: @user }) }
      end
    end
  end

  def destroy
    @follow = current_user.follows.find_by(user: @user)

    if @follow
      @follow.destroy
      # Reload associations to reflect changes
      current_user.following.reload
      @user.followers.reload

      respond_to do |format|
        format.html { redirect_to user_path(@user), notice: t("follows.unfollowed") }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to user_path(@user), alert: t("follows.not_following") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("follow-button-#{@user.id}", partial: "follows/button", locals: { user: @user }) }
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
