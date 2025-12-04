# frozen_string_literal: true

module ImageHelper
  def safe_image_tag(attachment, variant_options = {}, html_options = {})
    return nil unless attachment&.attached?
    
    begin
      if variant_options.present?
        image_tag url_for(attachment.variant(variant_options)), html_options
      else
        image_tag url_for(attachment), html_options
      end
    rescue ActiveStorage::FileNotFoundError, ActiveStorage::InvariableError
      # Return nil or a placeholder if image not found in R2
      content_tag(:div, 
        content_tag(:svg, 
          content_tag(:path, nil, 
            "stroke-linecap": "round", 
            "stroke-linejoin": "round", 
            "stroke-width": "1.5", 
            d: "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
          ),
          class: "w-16 h-16 text-gray-300",
          fill: "none",
          stroke: "currentColor",
          viewBox: "0 0 24 24"
        ),
        class: "#{html_options[:class]} bg-gradient-to-br from-gray-100 via-gray-50 to-gray-100 flex items-center justify-center",
        style: html_options[:style]
      )
    end
  end
  
  def safe_avatar_image(user, size: 40, html_options: {})
    return user_initials_avatar(user, size) unless user&.avatar&.attached?
    
    begin
      image_tag url_for(user.avatar.variant(resize_to_fill: [size, size])), 
        html_options.merge(class: "#{html_options[:class]} rounded-full object-cover")
    rescue ActiveStorage::FileNotFoundError, ActiveStorage::InvariableError
      user_initials_avatar(user, size, html_options)
    end
  end
  
  private
  
  def user_initials_avatar(user, size, html_options = {})
    initials = (user&.username&.first || user&.email&.first || 'U').upcase
    content_tag(:div, initials,
      class: "#{html_options[:class]} w-#{size/4} h-#{size/4} rounded-full bg-gradient-to-br from-emerald-400 via-teal-500 to-cyan-600 flex items-center justify-center text-white font-bold shadow-lg"
    )
  end
end

