# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      user = User.from_google(request.env.fetch("omniauth.auth"))

      set_flash_message! :notice, :success, kind: "Google"
      sign_in_and_redirect user, event: :authentication
    end

    def failure
      error = request.env["omniauth.error"]
      type = request.env["omniauth.error.type"]
      strategy = request.env["omniauth.error.strategy"]&.name || "unknown"
      message = error&.message.presence || "no exception message"

      Rails.logger.warn(
        "OmniAuth failure for #{strategy} (#{type || "unknown"}): #{error&.class || "no exception"} #{message}"
      )

      redirect_to new_user_session_path, alert: "Could not sign in."
    end
  end
end
