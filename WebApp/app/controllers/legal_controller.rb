class LegalController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def privacy
    @content = LegalPage.get('privacy', I18n.locale)
    @page_color = 'emerald'
  end

  def terms
    @content = LegalPage.get('terms', I18n.locale)
    @page_color = 'blue'
  end

  def cookies
    @content = LegalPage.get('cookies', I18n.locale)
    @page_color = 'amber'
  end
end

