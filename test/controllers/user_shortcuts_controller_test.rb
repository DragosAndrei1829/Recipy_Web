require "test_helper"

class UserShortcutsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get user_shortcuts_index_url
    assert_response :success
  end

  test "should get new" do
    get user_shortcuts_new_url
    assert_response :success
  end

  test "should get create" do
    get user_shortcuts_create_url
    assert_response :success
  end

  test "should get edit" do
    get user_shortcuts_edit_url
    assert_response :success
  end

  test "should get update" do
    get user_shortcuts_update_url
    assert_response :success
  end

  test "should get destroy" do
    get user_shortcuts_destroy_url
    assert_response :success
  end
end
