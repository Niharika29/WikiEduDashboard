# frozen_string_literal: true
require 'rails_helper'

describe 'cloning a course', js: true do
  before do
    Capybara.current_driver = :poltergeist
    page.current_window.resize_to(1920, 1920)
    stub_oauth_edit
  end
  # This is super hacky to work around a combination of bugginess in the modal
  # and bugginess in the Capybara drivers. We want to avoid setting a date the
  # same as today's date.
  if (11..12).cover? Date.today.day
    let(:course_start) { '13' }
    let(:timeline_start) { '14' }
  else
    let(:course_start) { '11' }
    let(:timeline_start) { '12' }
  end

  if (27..28).cover? Date.today.day
    let(:course_end) { '25' }
    let(:timeline_end) { '26' }
  else
    let(:course_end) { '27' }
    let(:timeline_end) { '28' }
  end

  let!(:course) do
    create(:course, id: 10001, start: 1.year.from_now.to_date,
                    end: 2.years.from_now.to_date, submitted: true,
                    expected_students: 0)
  end
  let!(:week)      { create(:week, course_id: course.id) }
  let!(:block)     { create(:block, week_id: week.id, due_date: course.start + 3.months) }
  let!(:gradeable) do
    create(:gradeable, gradeable_item_type: 'block', gradeable_item_id: block.id, points: 10)
  end
  let!(:user)      { create(:user, permissions: User::Permissions::ADMIN) }
  let!(:c_user)    { create(:courses_user, course_id: course.id, user_id: user.id) }
  let!(:term)      { 'Spring 2016' }
  let!(:desc)      { 'A new course' }

  it 'copies relevant attributes of an existing course' do
    login_as user, scope: :user, run_callbacks: false
    visit root_path

    click_link 'Create Course'
    click_button 'Clone Previous Course'
    select course.title, from: 'reuse-existing-course-select'
    click_button 'Clone This Course'

    expect(page).to have_content 'Course Successfully Cloned'

    # interact_with_clone_form
    find('input#course_term').click
    # For some reason, only the last character actually shows up, so we'll just add one.
    fill_in 'course_term', with: 'A'
    fill_in 'course_subject', with: 'B'
    within '#details_column' do
      find('input#course_start').click
      find('div.DayPicker-Day', text: course_start).click
      find('input#course_end').click
      find('div.DayPicker-Day', text: course_end).click
      find('input#timeline_start').click
      find('div.DayPicker-Day', text: timeline_start).click
      find('input#timeline_end').click
      find('div.DayPicker-Day', text: timeline_end).click
    end
    find('attr', text: 'MO').trigger('click')
    find('attr', text: 'WE').trigger('click')
    expect(page).to have_button('Save New Course', disabled: true)
    find('input[type="checkbox"]').click
    expect(page).not_to have_button('Save New Course', disabled: true)
    click_button 'Save New Course'

    expect(page).to have_current_path(/\(A\)/)

    new_course = Course.last
    expect(new_course.term).to eq('A')
    expect(new_course.subject).to eq('B')
    expect(new_course.weekdays).not_to eq('0000000')
    expect(Week.count).to eq(2) # make sure the weeks are distinct
    expect(new_course.blocks.first.content).to eq(course.blocks.first.content)
    expect(new_course.blocks.first.due_date)
      .to be_nil
    expect(new_course.blocks.first.gradeable.points).to eq(gradeable.points)
    expect(new_course.blocks.first.gradeable.gradeable_item_id)
      .to eq(new_course.blocks.first.id)
    expect(new_course.instructors.first).to eq(user)
    expect(new_course.submitted).to eq(false)
    expect(new_course.user_count).to be_zero
    expect(new_course.article_count).to be_zero
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
