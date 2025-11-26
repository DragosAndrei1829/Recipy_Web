class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :mark_read ]

  def index
    @notifications = current_user.notifications.includes(:recipe).recent
    @unread_count = current_user.unread_notifications.count
  end

  def mark_read
    if @notification.user == current_user
      @notification.mark_as_read!
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back(fallback_location: notifications_path, notice: t("notifications.marked_read")) }
      end
    else
      redirect_back(fallback_location: root_path, alert: t("notifications.unauthorized"))
    end
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read: true)
    redirect_to notifications_path, notice: t("notifications.all_marked_read")
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
  end
end
