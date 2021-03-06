# frozen_string_literal: true
class TrainingModulesController < ApplicationController
  respond_to :json

  def index
    @training_modules = TrainingModule.all.sort_by(&:id)
  end

  def show
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end
end
