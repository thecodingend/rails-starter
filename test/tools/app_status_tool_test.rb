require "test_helper"

class AppStatusToolTest < ActiveSupport::TestCase
  test "returns basic runtime information" do
    status = AppStatusTool.new.execute

    assert_equal Rails.env, status[:environment]
    assert_equal Rails.version, status[:rails_version]
    assert_equal RUBY_VERSION, status[:ruby_version]
    assert status[:current_time].present?
  end
end
