require "test_helper"

class VideoTimestampsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get video_timestamps_create_url
    assert_response :success
  end

  test "should get update" do
    get video_timestamps_update_url
    assert_response :success
  end

  test "should get destroy" do
    get video_timestamps_destroy_url
    assert_response :success
  end
end
