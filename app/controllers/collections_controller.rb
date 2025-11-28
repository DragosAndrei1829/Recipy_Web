# frozen_string_literal: true

class CollectionsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :public_index]
  before_action :set_collection, only: [:show, :edit, :update, :destroy, :add_recipe, :remove_recipe]
  before_action :authorize_collection_access!, only: [:show]
  before_action :authorize_collection_owner!, only: [:edit, :update, :destroy, :add_recipe, :remove_recipe]

  def index
    @collections = current_user.collections.includes(:recipes, :user).recent
    @public_collections = Collection.public_collections.includes(:user, :recipes).recent.limit(10)
  end

  def public_index
    @collections = Collection.public_collections.includes(:user, :recipes).recent.limit(20)
  end

  def show
    @collection_recipes = @collection.collection_recipes.includes(recipe: [:user, :category, :cuisine]).ordered
    @can_edit = @collection.owned_by?(current_user) if user_signed_in?
  end

  def new
    @collection = current_user.collections.build
  end

  def create
    @collection = current_user.collections.build(collection_params)

    if @collection.save
      redirect_to collection_path(@collection), notice: "Colecția a fost creată cu succes!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @collection.update(collection_params)
      redirect_to collection_path(@collection), notice: "Colecția a fost actualizată cu succes!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection.destroy
    redirect_to collections_path, notice: "Colecția a fost ștearsă cu succes!"
  end

  def add_recipe
    recipe = Recipe.find(params[:recipe_id])
    note = params[:note]

    if @collection.add_recipe(recipe, note: note)
      redirect_back(fallback_location: collection_path(@collection), notice: "Rețeta a fost adăugată în colecție!")
    else
      redirect_back(fallback_location: collection_path(@collection), alert: "Rețeta este deja în colecție.")
    end
  end

  def remove_recipe
    recipe = Recipe.find(params[:recipe_id])

    if @collection.remove_recipe(recipe)
      redirect_back(fallback_location: collection_path(@collection), notice: "Rețeta a fost eliminată din colecție!")
    else
      redirect_back(fallback_location: collection_path(@collection), alert: "Rețeta nu a fost găsită în colecție.")
    end
  end

  def reorder
    @collection = current_user.collections.find(params[:id])
    recipe_ids = params[:recipe_ids]

    if recipe_ids.present?
      @collection.reorder_recipes(recipe_ids)
      head :ok
    else
      head :unprocessable_entity
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
      redirect_to collections_path, alert: "Nu ai acces la această colecție."
    end
  end

  def authorize_collection_owner!
    unless @collection.owned_by?(current_user)
      redirect_to collections_path, alert: "Nu ai permisiunea să modifici această colecție."
    end
  end
end

