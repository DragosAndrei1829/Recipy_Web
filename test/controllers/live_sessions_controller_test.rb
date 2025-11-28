require "test_helper"

class LiveSessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get live_sessions_index_url
    assert_response :success
  end

  test "should get show" do
    get live_sessions_show_url
    assert_response :success
  end

  test "should get new" do
    get live_sessions_new_url
    assert_response :success
  end

  test "should get create" do
    get live_sessions_create_url
    assert_response :success
  end

  test "should get update" do
    get live_sessions_update_url
    assert_response :success
  end

  test "should get destroy" do
    get live_sessions_destroy_url
    assert_response :success
  end

  test "should get start" do
    get live_sessions_start_url
    assert_response :success
  end

  test "should get end" do
    get live_sessions_end_url
    assert_response :success
  end
end
