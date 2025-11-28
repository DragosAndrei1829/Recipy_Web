# frozen_string_literal: true

class ShoppingListItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shopping_list
  before_action :set_item, only: [:update, :destroy, :toggle_checked]

  def create
    @item = @shopping_list.shopping_list_items.build(item_params)
    @item.position = @shopping_list.shopping_list_items.count

    if @item.save
      redirect_to @shopping_list, notice: "Item adăugat!"
    else
      redirect_to @shopping_list, alert: "Eroare la adăugarea item-ului: #{@item.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @item.update(item_params)
      redirect_to @shopping_list, notice: "Item actualizat!"
    else
      redirect_to @shopping_list, alert: "Eroare la actualizarea item-ului!"
    end
  end

  def destroy
    @item.destroy
    redirect_to @shopping_list, notice: "Item șters!"
  end

  def toggle_checked
    @item.toggle_checked!
    
    respond_to do |format|
      format.html { redirect_to @shopping_list }
      format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@item), partial: "shopping_list_items/item", locals: { item: @item, shopping_list: @shopping_list }) }
      format.json { render json: { checked: @item.checked, progress: @shopping_list.progress_percentage } }
    end
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:shopping_list_id])
  end

  def set_item
    @item = @shopping_list.shopping_list_items.find(params[:id])
  end

  def item_params
    params.require(:shopping_list_item).permit(:ingredient_name, :quantity, :unit, :category, :position)
  end
end
