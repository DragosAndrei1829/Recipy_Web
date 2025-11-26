class ContactController < ApplicationController
  def show
    @site_setting = SiteSetting.instance
  end
end

