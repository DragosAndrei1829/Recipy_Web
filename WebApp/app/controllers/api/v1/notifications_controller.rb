module Api
  module V1
    class NotificationsController < BaseController
      # GET /api/v1/notifications
      def index
        notifications = current_api_user.notifications.order(created_at: :desc)

        paginated = paginate(notifications)
        render_success({
          notifications: paginated[:items].map { |n| notification_json(n) },
          pagination: paginated[:pagination],
          unread_count: current_api_user.notifications.where(read: false).count
        })
      end

      # GET /api/v1/notifications/unread_count
      def unread_count
        render_success({
          unread_count: current_api_user.notifications.where(read: false).count
        })
      end

      # PATCH /api/v1/notifications/:id/read
      def mark_read
        notification = current_api_user.notifications.find(params[:id])
        notification.update(read: true)

        render_success({
          notification: notification_json(notification),
          unread_count: current_api_user.notifications.where(read: false).count
        })
      end

      # POST /api/v1/notifications/mark_all_read
      def mark_all_read
        current_api_user.notifications.where(read: false).update_all(read: true)

        render_success({
          message: "All notifications marked as read",
          unread_count: 0
        })
      end

      # DELETE /api/v1/notifications/:id
      def destroy
        notification = current_api_user.notifications.find(params[:id])
        notification.destroy

        render_success({ message: "Notification deleted" })
      end

      private

      def notification_json(notification)
        {
          id: notification.id,
          type: notification.notification_type,
          title: notification.title,
          message: notification.message,
          read: notification.read,
          recipe_id: notification.recipe_id,
          created_at: notification.created_at
        }
      end
    end
  end
end




