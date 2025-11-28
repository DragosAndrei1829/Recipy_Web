# frozen_string_literal: true

class ShoppingListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shopping_list, only: [:show, :edit, :update, :destroy, :complete, :archive]

  def index
    @shopping_lists = current_user.shopping_lists.order(created_at: :desc)
    @active_lists = @shopping_lists.active
    @completed_lists = @shopping_lists.completed
    @archived_lists = @shopping_lists.archived
  end

  def show
    @items = @shopping_list.shopping_list_items.ordered
    @items_by_category = @items.group_by(&:category)
  end

  def new
    @shopping_list = current_user.shopping_lists.build
  end

  def create
    @shopping_list = current_user.shopping_lists.build(shopping_list_params)

    if @shopping_list.save
      redirect_to @shopping_list, notice: "Listă de cumpărături creată cu succes!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Already set by before_action
  end

  def update
    if @shopping_list.update(shopping_list_params)
      redirect_to @shopping_list, notice: "Listă actualizată cu succes!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @shopping_list.destroy
    redirect_to shopping_lists_path, notice: "Listă ștearsă cu succes!"
  end

  def complete
    @shopping_list.complete!
    redirect_to @shopping_list, notice: "Listă marcată ca finalizată!"
  end

  def archive
    @shopping_list.archive!
    redirect_to shopping_lists_path, notice: "Listă arhivată!"
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:id])
  end

  def shopping_list_params
    params.require(:shopping_list).permit(:name, :status)
  end
end
