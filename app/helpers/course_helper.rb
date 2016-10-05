# frozen_string_literal: true
#= Helpers for course views
module CourseHelper
  def find_course_by_slug(slug)
    course = Course.find_by_slug(slug)
    if course.nil?
      raise ActionController::RoutingError.new('Not Found'), "Course #{slug} not found"
    end
    return course
  end

  def current?(course)
    course.current?
  end

  def pretty_course_title(course)
    "#{course.school} - #{course.title} (#{course.term})"
  end

  def date_highlight_class(course)
    return 'table-row--warning' if 1.week.from_now > course.end
    return 'table-row--info' if course.start > 1.week.ago
    return ''
  end

  def course_i18n(prefix, messageKey)
    return t(`${prefix}.${messageKey}`);
  end
end
