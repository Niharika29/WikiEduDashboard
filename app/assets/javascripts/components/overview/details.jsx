import React from 'react';

import InlineUsers from './inline_users.jsx';
import CohortButton from './cohort_button.jsx';
import TagButton from './tag_button.jsx';
import CourseTypeSelector from './course_type_selector.jsx';
import Editable from '../high_order/editable.jsx';
import TextInput from '../common/text_input.jsx';
import DatePicker from '../common/date_picker.jsx';
import CourseActions from '../../actions/course_actions.js';

import CourseStore from '../../stores/course_store.coffee';
import TagStore from '../../stores/tag_store.js';
import UserStore from '../../stores/user_store.js';
import CohortStore from '../../stores/cohort_store.js';

import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.coffee';
// For some reason getState is not being triggered when CohortStore gets updated

const getState = () =>
  ({
    course: CourseStore.getCourse(),
    cohorts: CohortStore.getModels(),
    instructors: UserStore.getFiltered({ role: 1 }),
    online: UserStore.getFiltered({ role: 2 }),
    campus: UserStore.getFiltered({ role: 3 }),
    staff: UserStore.getFiltered({ role: 4 }),
    tags: TagStore.getModels()
  })
;

const Details = React.createClass({
  displayName: 'Details',

  propTypes: {
    course: React.PropTypes.object,
    current_user: React.PropTypes.object,
    instructors: React.PropTypes.array,
    online: React.PropTypes.array,
    campus: React.PropTypes.array,
    staff: React.PropTypes.array,
    cohorts: React.PropTypes.array,
    tags: React.PropTypes.array,
    controls: React.PropTypes.func,
    editable: React.PropTypes.bool
  },

  getInitialState() {
    return getState();
  },

  updateDetails(valueKey, value) {
    const updatedCourse = this.props.course;
    updatedCourse[valueKey] = value;
    return CourseActions.updateCourse(updatedCourse);
  },

  updateSlugPart(valueKey, value) {
    const updatedCourse = this.props.course;
    updatedCourse[valueKey] = value;
    updatedCourse.slug = CourseUtils.generateTempId(updatedCourse);
    return CourseActions.updateCourse(updatedCourse);
  },

  updateCourseDates(valueKey, value) {
    const updatedCourse = CourseDateUtils.updateCourseDates(this.props.course, valueKey, value);
    return CourseActions.updateCourse(updatedCourse);
  },

  render() {
    let instructors = <InlineUsers {...this.props} users={this.props.instructors} role={1} title={CourseUtils.i18n('instructors', this.props.course.string_prefix)} />;
    let online = <InlineUsers {...this.props} users={this.props.online} role={2} title="Online Volunteers" />;
    let campus = <InlineUsers {...this.props} users={this.props.campus} role={3} title="Campus Volunteers" />;
    let staff;
    if (Features.wikiEd) {
      staff = <InlineUsers {...this.props} users={this.props.staff} role={4} title="Wiki Ed Staff" />;
    }
    let school;
    if (this.props.course.school || this.props.current_user.admin) {
      school = (
        <TextInput
          onChange={this.updateSlugPart}
          value={this.props.course.school}
          value_key="school"
          editable={this.props.editable && this.props.current_user.admin}
          type="text"
          label={CourseUtils.i18n('school', this.props.course.string_prefix)}
          required={true}
        />
      );
    }

    let title;
    if (this.props.editable && this.props.current_user.admin) {
      title = (
        <TextInput
          onChange={this.updateSlugPart}
          value={this.props.course.title}
          value_key="title"
          editable={this.props.editable && this.props.current_user.admin}
          type="text"
          label={CourseUtils.i18n('title', this.props.course.string_prefix)}
          required={true}
        />
      );
    }

    let term;
    if (this.props.course.term || this.props.current_user.admin) {
      term = (
        <TextInput
          onChange={this.updateSlugPart}
          value={this.props.course.term}
          value_key="term"
          editable={this.props.editable && this.props.current_user.admin}
          type="text"
          label={CourseUtils.i18n('term', this.props.course.string_prefix)}
          required={false}
        />
      );
    }

    let passcode;
    if (this.props.course.passcode || this.props.editable) {
      passcode = (
        <TextInput
          onChange={this.updateDetails}
          value={this.props.course.passcode}
          value_key="passcode"
          editable={this.props.editable}
          type="text"
          label={I18n.t('courses.passcode')}
          placeholder={I18n.t('courses.passcode_none')}
          required={true}
        />
      );
    }

    let expectedStudents;
    if (this.props.course.expected_students) {
      expectedStudents = (
        <TextInput
          onChange={this.updateDetails}
          value={String(this.props.course.expected_students)}
          value_key="expected_students"
          editable={this.props.editable}
          type="number"
          label={CourseUtils.i18n('expected_students', this.props.course.string_prefix)}
        />
      );
    }


    const dateProps = CourseDateUtils.dateProps(this.props.course);
    let timelineStart;
    let timelineEnd;
    if (this.props.course.type === 'ClassroomProgramCourse') {
      timelineStart = (
        <DatePicker
          onChange={this.updateCourseDates}
          value={this.props.course.timeline_start}
          value_key="timeline_start"
          editable={this.props.editable}
          validation={CourseDateUtils.isDateValid}
          label={CourseUtils.i18n('assignment_start', this.props.course.string_prefix)}
          date_props={dateProps.timeline_start}
          required={true}
        />
      );
      timelineEnd = (
        <DatePicker
          onChange={this.updateCourseDates}
          value={this.props.course.timeline_end}
          value_key="timeline_end"
          editable={this.props.editable}
          validation={CourseDateUtils.isDateValid}
          label={CourseUtils.i18n('assignment_end', this.props.course.string_prefix)}
          date_props={dateProps.timeline_end}
          required={true}
        />
      );
    }

    let cohorts = this.props.cohorts.length > 0 ?
      _.map(this.props.cohorts, 'title').join(', ')
    : I18n.t('courses.none');


    let subject;
    let tags;
    let courseTypeSelector;
    if (this.props.current_user.admin) {
      let tagsList = this.props.tags.length > 0 ?
        _.map(this.props.tags, 'tag').join(', ')
      : I18n.t('courses.none');

      subject = (
        <div className="subject">
          <span><strong>Subject:</strong> {this.props.course.subject}</span>
        </div>
      );
      tags = (
        <div className="tags">
          <span><strong>Tags:</strong> {tagsList}</span>
          <TagButton {...this.props} show={this.props.editable} />
        </div>
      );
      courseTypeSelector = (
        <CourseTypeSelector
          course={this.props.course}
          editable={this.props.editable}
        />
      );
    }

    return (
      <div className="module course-details">
        <div className="section-header">
          <h3>Details</h3>
          {this.props.controls()}
        </div>
        <div className="module__data extra-line-height">
          {instructors}
          {title}
          {term}
          <form>
            {passcode}
            {expectedStudents}
            <DatePicker
              onChange={this.updateCourseDates}
              value={this.props.course.start}
              value_key="start"
              validation={CourseDateUtils.isDateValid}
              editable={this.props.editable}
              label={I18n.t('courses.start')}
              required={true}
            />
            <DatePicker
              onChange={this.updateCourseDates}
              value={this.props.course.end}
              value_key="end"
              editable={this.props.editable}
              validation={CourseDateUtils.isDateValid}
              label={I18n.t('courses.end')}
              date_props={dateProps.end}
              enabled={Boolean(this.props.course.start)}
              required={true}
            />
            {timelineStart}
            {timelineEnd}
          </form>
          <div>
            <span><strong>{I18n.t('courses.campaigns')}</strong>{cohorts}</span>
            <CohortButton {...this.props} show={this.props.editable && this.props.current_user.admin && (this.props.course.submitted || this.props.course.type !== 'ClassroomProgramCourse') } />
          </div>
          {subject}
          {tags}
          {courseTypeSelector}
        </div>
      </div>
    );
  }
}
);

export default Editable(Details, [CourseStore, UserStore, CohortStore, TagStore], CourseActions.persistCourse, getState, 'Edit Details');
