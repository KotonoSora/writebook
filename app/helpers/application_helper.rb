module ApplicationHelper
  def app_name
    ENV.fetch("APP_NAME", "Storynest")
  end

  def site_logo_asset
    ENV.fetch("APP_LOGO_ASSET", "site-logo.svg")
  end

  def join_share_title
    "Link to join #{app_name}"
  end

  def join_share_text
    "Hit this link to join me in #{app_name} and start writing."
  end

  def hide_from_user_style_tag
    tag.style(<<~CSS.html_safe)
      [data-hide-from-user-id="#{Current.user.id}"] {
        display: none!important;
      }
    CSS
  end

  def custom_styles_tag
    if custom_styles = Current.account&.custom_styles
      tag.style(custom_styles.to_s.html_safe, data: { turbo_track: "reload" })
    end
  end
end
