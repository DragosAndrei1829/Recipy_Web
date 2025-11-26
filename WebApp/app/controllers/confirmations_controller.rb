class ConfirmationsController < ApplicationController
  before_action :set_user, only: [ :show, :verify ]

  def show
    # Show the confirmation code input page
    redirect_to new_user_session_path(locale: I18n.locale), alert: t("confirmation.user_not_found") unless @user
  end

  def verify
    code = params[:code]

    if code.blank?
      flash.now[:alert] = t("confirmation.code_required")
      render :show, status: :unprocessable_entity
      return
    end

    if @user.confirm_email_with_code!(code)
      flash[:notice] = t("confirmation.success")
      redirect_to new_user_session_path(locale: I18n.locale)
    else
      flash.now[:alert] = t("confirmation.invalid_code")
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by(id: params[:user_id])
  end
end
