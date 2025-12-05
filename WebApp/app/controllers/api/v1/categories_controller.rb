module Api
  module V1
    class CategoriesController < BaseController
      skip_before_action :authenticate_api_user!

      # GET /api/v1/categories
      def index
        categories = Category.all.order(:name)
        render_success({
          categories: categories.map { |c| { id: c.id, name: c.name } }
        })
      end

      # GET /api/v1/cuisines
      def cuisines
        cuisines = Cuisine.all.order(:name)
        render_success({
          cuisines: cuisines.map { |c| { id: c.id, name: c.name } }
        })
      end

      # GET /api/v1/food_types
      def food_types
        food_types = FoodType.all.order(:name)
        render_success({
          food_types: food_types.map { |f| { id: f.id, name: f.name } }
        })
      end
    end
  end
end




