# frozen_string_literal: true

class MealPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_meal_plan, only: [:show, :edit, :update, :destroy]

  def index
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_week
    @end_date = @start_date + 6.days
    @meal_plans = current_user.meal_plans.for_user_and_date_range(current_user, @start_date, @end_date)
    @meal_plans_by_date = @meal_plans.group_by(&:planned_for)
  end

  def show
    # Already set by before_action
  end

  def new
    @meal_plan = current_user.meal_plans.build
    @recipe = Recipe.find(params[:recipe_id]) if params[:recipe_id]
    @meal_plan.recipe = @recipe if @recipe
    @meal_plan.planned_for = params[:date] ? Date.parse(params[:date]) : Date.current
    @meal_plan.meal_type = params[:meal_type] || "dinner"
  end

  def create
    @meal_plan = current_user.meal_plans.build(meal_plan_params)

    if @meal_plan.save
      redirect_to meal_plans_path(start_date: @meal_plan.planned_for.beginning_of_week), notice: "Masă planificată cu succes!"
    else
      @recipe = @meal_plan.recipe
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Already set by before_action
  end

  def update
    if @meal_plan.update(meal_plan_params)
      redirect_to meal_plans_path(start_date: @meal_plan.planned_for.beginning_of_week), notice: "Planificare actualizată cu succes!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    planned_date = @meal_plan.planned_for
    @meal_plan.destroy
    redirect_to meal_plans_path(start_date: planned_date.beginning_of_week), notice: "Masă eliminată din planificare!"
  end

  def week_view
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_week
    @end_date = @start_date + 6.days
    @meal_plans = current_user.meal_plans.for_user_and_date_range(current_user, @start_date, @end_date)
    @meal_plans_by_date = @meal_plans.group_by(&:planned_for)
    @meal_plans_by_type = @meal_plans.group_by(&:meal_type)
  end

  def generate_shopping_list
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_week
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : start_date + 6.days
    
    meal_plans = current_user.meal_plans.for_user_and_date_range(current_user, start_date, end_date)
    
    if meal_plans.empty?
      redirect_to meal_plans_path, alert: "Nu ai mese planificate pentru această perioadă!"
      return
    end

    shopping_list = current_user.shopping_lists.create!(
      name: "Listă de cumpărături - #{start_date.strftime('%d.%m')} - #{end_date.strftime('%d.%m')}",
      status: "active"
    )

    shopping_list.generate_from_meal_plans!(meal_plans)

    redirect_to shopping_list_path(shopping_list), notice: "Listă de cumpărături generată cu succes!"
  end

  private

  def set_meal_plan
    @meal_plan = current_user.meal_plans.find(params[:id])
  end

  def meal_plan_params
    params.require(:meal_plan).permit(:recipe_id, :meal_type, :planned_for, :servings, :notes)
  end
end
