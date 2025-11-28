require "test_helper"

class MealPlansControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get meal_plans_index_url
    assert_response :success
  end

  test "should get show" do
    get meal_plans_show_url
    assert_response :success
  end

  test "should get new" do
    get meal_plans_new_url
    assert_response :success
  end

  test "should get create" do
    get meal_plans_create_url
    assert_response :success
  end

  test "should get edit" do
    get meal_plans_edit_url
    assert_response :success
  end

  test "should get update" do
    get meal_plans_update_url
    assert_response :success
  end

  test "should get destroy" do
    get meal_plans_destroy_url
    assert_response :success
  end

  test "should get week_view" do
    get meal_plans_week_view_url
    assert_response :success
  end

  test "should get generate_shopping_list" do
    get meal_plans_generate_shopping_list_url
    assert_response :success
  end
end
