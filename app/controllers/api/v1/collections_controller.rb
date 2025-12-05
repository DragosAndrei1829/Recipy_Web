# frozen_string_literal: true

module Api
  module V1
    class CollectionsController < BaseController
      before_action :authenticate_user!, except: [:show, :public_index]
      before_action :set_collection, only: [:show, :update, :destroy, :add_recipe, :remove_recipe]
      before_action :authorize_collection_access!, only: [:show]
      before_action :authorize_collection_owner!, only: [:update, :destroy, :add_recipe, :remove_recipe]

      # GET /api/v1/collections
      # List user's collections
      def index
        collections = current_user.collections.includes(:recipes, :user).recent

        render_success(collections: collections.map { |c| collection_json(c) })
      end

      # GET /api/v1/collections/public
      # List public collections
      def public_index
        collections = Collection.public_collections.includes(:user, :recipes).recent
                              .limit(params[:limit] || 20)
                              .offset(params[:offset] || 0)

        render_success(collections: collections.map { |c| collection_json(c) })
      end

      # GET /api/v1/collections/:id
      # Show collection details
      def show
        render_success(collection: collection_json(@collection, include_recipes: true))
      end

      # POST /api/v1/collections
      # Create a new collection
      def create
        collection = current_user.collections.build(collection_params)

        if collection.save
          render_success({ collection: collection_json(collection) }, :created)
        else
          render_error(collection.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # PUT /api/v1/collections/:id
      # Update collection
      def update
        if @collection.update(collection_params)
          render_success(collection: collection_json(@collection))
        else
          render_error(@collection.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # DELETE /api/v1/collections/:id
      # Delete collection
      def destroy
        @collection.destroy
        render_success(message: "Colecția a fost ștearsă cu succes")
      end

      # POST /api/v1/collections/:id/add_recipe
      # Add recipe to collection
      def add_recipe
        recipe = Recipe.find(params[:recipe_id])
        note = params[:note]

        if @collection.add_recipe(recipe, note: note)
          render_success(message: "Rețeta a fost adăugată în colecție", collection: collection_json(@collection))
        else
          render_error("Rețeta este deja în colecție", :unprocessable_entity)
        end
      end

      # DELETE /api/v1/collections/:id/remove_recipe
      # Remove recipe from collection
      def remove_recipe
        recipe = Recipe.find(params[:recipe_id])

        if @collection.remove_recipe(recipe)
          render_success(message: "Rețeta a fost eliminată din colecție", collection: collection_json(@collection))
        else
          render_error("Rețeta nu a fost găsită în colecție", :unprocessable_entity)
        end
      end

      private

      def set_collection
        @collection = Collection.find(params[:id])
      end

      def collection_params
        params.require(:collection).permit(:name, :description, :is_public, :cover_image)
      end

      def authorize_collection_access!
        unless @collection.viewable_by?(current_user)
          render_error("Nu ai acces la această colecție", :forbidden)
        end
      end

      def authorize_collection_owner!
        unless @collection.owned_by?(current_user)
          render_error("Nu ai permisiunea să modifici această colecție", :forbidden)
        end
      end

      def collection_json(collection, include_recipes: false, include_invite_code: false)
        json = {
          id: collection.id,
          name: collection.name,
          description: collection.description,
          is_public: collection.is_public,
          recipes_count: collection.recipes_count,
          created_at: collection.created_at,
          updated_at: collection.updated_at,
          user: {
            id: collection.user.id,
            username: collection.user.username,
            avatar_url: collection.user.avatar.attached? ? url_for(collection.user.avatar.variant(resize_to_fill: [100, 100])) : nil
          }
        }

        if collection.cover_image.attached? && collection.cover_image.blob.present?
          json[:cover_image_url] = url_for(collection.cover_image.variant(resize_to_fill: [800, 400]))
        end

        if include_recipes
          json[:recipes] = collection.collection_recipes.ordered.map do |cr|
            {
              id: cr.recipe.id,
              title: cr.recipe.title,
              note: cr.note,
              position: cr.position,
              cover_photo_url: cr.recipe.cover_photo.present? && cr.recipe.cover_photo.blob.present? ? 
                url_for(cr.recipe.cover_photo.variant(resize_to_fill: [400, 300])) : nil
            }
          end
        end

        json
      end
    end
  end
end




