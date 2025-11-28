require "test_helper"

class ShoppingListItemsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get shopping_list_items_create_url
    assert_response :success
  end

  test "should get update" do
    get shopping_list_items_update_url
    assert_response :success
  end

  test "should get destroy" do
    get shopping_list_items_destroy_url
    assert_response :success
  end

  test "should get toggle_checked" do
    get shopping_list_items_toggle_checked_url
    assert_response :success
  end
end
