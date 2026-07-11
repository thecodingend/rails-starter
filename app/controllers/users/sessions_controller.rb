# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def new
      render inertia: "auth/sign_in"
    end

    private

    # Devise defaults to the root path, which requires authentication and
    # bounces the just-signed-out user through a failure response.
    def after_sign_out_path_for(_resource)
      new_user_session_path
    end
  end
end
