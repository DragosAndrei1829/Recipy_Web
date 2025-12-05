# frozen_string_literal: true

module DeviceHelper
  def mobile_device?
    request.user_agent =~ /Mobile|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i
  end
  
  def tablet_device?
    request.user_agent =~ /iPad|Android(?!.*Mobile)/i
  end
  
  def desktop_device?
    !mobile_device? && !tablet_device?
  end
end




