require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "renders sign in page through inertia" do
    get new_user_session_path

    assert_inertia_response
    assert_inertia_component "auth/sign_in"
  end

  test "renders sign up page through inertia" do
    get new_user_registration_path

    assert_inertia_response
    assert_inertia_component "auth/sign_up"
  end

  test "signs in with email and password" do
    post user_session_path, params: {
      user: {
        email: users(:regular).email,
        password: "password123"
      }
    }

    assert_redirected_to root_path
  end

  test "shares current user with inertia pages" do
    sign_in users(:regular)

    get "/inertia-example"

    assert_inertia_response
    assert_inertia_props auth: {
      user: {
        id: users(:regular).id,
        email: "regular@example.com",
        role: "regular"
      }
    }
  end

  test "returns registration errors through inertia redirect" do
    post user_registration_path, params: {
      user: {
        email: "",
        password: "short",
        password_confirmation: "different"
      }
    }

    assert_redirected_to new_user_registration_path

    follow_redirect!

    assert_inertia_response
    assert_inertia_component "auth/sign_up"
    assert_inertia_props errors: {
      email: [ "Email can't be blank" ],
      password: [ "Password is too short (minimum is 6 characters)" ],
      password_confirmation: [ "Password confirmation doesn't match Password" ]
    }
  end

  test "returns invalid confirmation tokens to the inertia confirmation page" do
    get user_confirmation_path(confirmation_token: "bad-token")

    assert_redirected_to new_user_confirmation_path

    follow_redirect!

    assert_inertia_response
    assert_inertia_component "auth/confirmations/new"
  end
end
