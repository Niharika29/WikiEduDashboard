# frozen_string_literal: true
require "#{Rails.root}/lib/wiki_course_edits"
require "#{Rails.root}/lib/importers/user_importer"

#= Controller for user functionality
class UsersController < ApplicationController
  respond_to :html, :json
  before_action :require_participating_user,
                only: [:save_assignments, :enroll]

  before_action :require_signed_in, only: [:update_locale]

  def signout
    if current_user.nil?
      redirect_to '/'
    else
      current_user.update_attributes(wiki_token: nil, wiki_secret: nil)
      redirect_to true_destroy_user_session_path
    end
  end

  def update_locale
    locale = params[:locale]

    unless I18n.available_locales.include?(locale.to_sym)
      render json: { message: 'Invalid locale' }, status: :unprocessable_entity
      return
    end

    current_user.locale = locale
    current_user.save!
    render json: { success: true }
  end

  #########################
  # Enrollment management #
  #########################
  def enroll
    if request.post?
      add
    elsif request.delete?
      remove
    end
  end

  ####################################################
  # Page for showing course info for particular user #
  ####################################################
  def show
    @user = User.find_by_username(params[:username])
    if @user
      @course = @user.courses
    else
      flash[:notice] = 'User not found'
      redirect_to controller: 'dashboard', action: 'index'
    end
  end


  private

  #################
  # Adding a user #
  #################
  def add
    set_course_and_user
    ensure_user_exists { return }
    @result = JoinCourse.new(course: @course,
                             user: @user,
                             role: enroll_params[:role]).result
    ensure_enrollment_success { return }

    WikiCourseEdits.new(action: :update_course, course: @course, current_user: current_user)
    render 'users', formats: :json
  end

  def ensure_user_exists
    return unless @user.nil?
    username = enroll_params[:user_id] || enroll_params[:username]
    render json: { message: I18n.t('courses.error.user_exists', username: username) },
           status: 404
    yield
  end

  def ensure_enrollment_success
    return unless @result[:failure]
    render json: { message: @result[:failure] },
           status: 404
    yield
  end

  ###################
  # Removing a user #
  ###################
  def remove
    set_course_and_user
    return if @user.nil?

    @course_user = CoursesUsers.find_by(user_id: @user.id,
                                        course_id: @course.id,
                                        role: enroll_params[:role])
    return if @course_user.nil? # This will happen if the user was already removed.

    remove_assignment_templates
    @course_user.destroy # destroying the course_user also destroys associated Assignments.

    render 'users', formats: :json
    WikiCourseEdits.new(action: :update_course, course: @course, current_user: current_user)
  end

  # If the user has Assignments, update article talk pages to remove them from
  # the assignment templates.
  def remove_assignment_templates
    assignments = @course_user.assignments
    assignments.each do |assignment|
      WikiCourseEdits.new(action: :remove_assignment,
                          course: @course,
                          current_user: current_user,
                          assignment: assignment)
    end
  end

  ##################
  # Finding a user #
  ##################
  def set_course_and_user
    @course = Course.find_by_slug(params[:id])
    if enroll_params.key? :user_id
      @user = User.find(enroll_params[:user_id])
    elsif enroll_params.key? :username
      find_or_import_user_by_username
    end
  end

  def find_or_import_user_by_username
    username = enroll_params[:username]
    @user = User.find_by(username: username)
    @user = UserImporter.new_from_username(username) if @user.nil?
  end

  def enroll_params
    params.require(:user).permit(:user_id, :username, :role)
  end
end
