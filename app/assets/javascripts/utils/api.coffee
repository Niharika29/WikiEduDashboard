{ capitalize } = require './strings'

logErrorMessage = (obj, prefix) ->
  # readyState 0 usually indicates that the user navigated away before ajax
  # requests resolved.
  return if obj.readyState == 0
  message = prefix || 'Error: '
  message += obj.responseJSON?.message || obj.statusText
  console.log message

RavenLogger = {}

API =
  ###########
  # Getters #
  ###########
  fetchLookups: (model) ->
    new Promise (res, rej) =>
      $.ajax
        type: 'GET',
        url: "/lookups/#{model}.json",
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchWizardIndex: ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/wizards.json',
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchRevisions: (studentId, courseId) ->
    new Promise (res, rej) ->
      url = "/revisions.json?user_id=#{studentId}&course_id=#{courseId}"
      $.ajax
        type: 'GET',
        url: url
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchTrainingStatus: (studentId, courseId) ->
    new Promise (res, rej) ->
      url = "/training_status.json?user_id=#{studentId}&course_id=#{courseId}"
      $.ajax
        type: 'GET',
        url: url
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchDykArticles: (opts={}) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: "/revision_analytics/dyk_eligible.json?scoped=#{opts.scoped || false}",
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchSuspectedPlagiarism: (opts={}) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: "/revision_analytics/suspected_plagiarism.json?scoped=#{opts.scoped || false}",
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchRecentEdits: (opts={}) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: "/revision_analytics/recent_edits.json?scoped=#{opts.scoped || false}",
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchRecentUploads: (opts={}) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: "/revision_analytics/recent_uploads.json?scoped=#{opts.scoped || false}",
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  cloneCourse: (id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: "/clone_course/#{id}",
        success: (data) ->
          console.log 'Received course clone'
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchCohorts: ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/cohorts.json',
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchWizardPanels: (wizard_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/wizards/' + wizard_id + '.json',
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchUserCourses: (userId) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: "/courses_users.json?user_id=#{userId}"
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  deleteAssignment: (assignment) ->
    queryString = $.param(assignment)
    new Promise (res, rej) ->
      $.ajax
        type: 'DELETE',
        url: "/assignments/#{assignment.assignment_id}?#{queryString}"
        success: (data) ->
          console.log 'Deleted assignment'
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  createAssignment: (opts) ->
    queryString = $.param(opts)
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: "/assignments.json?#{queryString}"
        success: (data) ->
          console.log 'Created assignment'
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  updateAssignment: (opts) ->
    queryString = $.param(opts)
    new Promise (res, rej) ->
      $.ajax
        type: 'PUT',
        url: "/assignments/#{opts.id}.json?#{queryString}"
        success: (data) ->
          console.log 'Updated assignment'
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj


  fetch: (course_id, endpoint) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/courses/' + course_id + '/' + endpoint + '.json',
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchAllTrainingModules: (opts) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET'
        url: "/training_modules.json"
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  fetchTrainingModule: (opts) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET'
        url: "/training_module.json?module_id=#{opts.module_id}"
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  setSlideCompleted: (opts) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST'
        url: "/training_modules_users.json?\
          module_id=#{opts.module_id}&\
          user_id=#{opts.user_id}&\
          slide_id=#{opts.slide_id}"
        success: (data) ->
          console.log 'Slide completed'
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  ###########
  # Setters #
  ###########
  saveTimeline: (course_id, data) ->
    promise = new Promise (res, rej) ->
      cleanup = (array) ->
        for obj in array
          if obj.is_new
            delete obj.id
            delete obj.is_new

      weeks = data.weeks
      blocks = data.blocks
      gradeables = data.gradeables

      for week in weeks
        week.blocks = []
        for block in blocks
          week.blocks.push block if block.week_id == week.id
          for gradeable in gradeables
            if gradeable.gradeable_item_id == block.id
              block.gradeable = gradeable
              delete gradeable.gradeable_item_id if block.is_new

      cleanup weeks
      cleanup blocks
      cleanup gradeables

      req_data = weeks: weeks
      RavenLogger['type'] = 'POST'

      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/timeline.json',
        contentType: 'application/json',
        data: JSON.stringify(req_data)
        success: (data) ->
          console.log 'Saved timeline!'
          res data
      .fail (obj, status) ->
        @obj = obj
        @status = status
        console.error 'Couldn\'t save timeline!'
        RavenLogger['obj'] = @obj
        RavenLogger['status'] = @status
        Raven.captureMessage('saveTimeline failed',
                             level: 'error',
                             extra: RavenLogger)
        rej obj
    promise
  saveGradeables: (course_id, data) ->
    new Promise (res, rej) ->
      cleanup = (array) ->
        for obj in array
          if obj.is_new
            delete obj.id
            delete obj.is_new

      gradeables = data.gradeables
      cleanup gradeables

      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/gradeables.json',
        contentType: 'application/json',
        data: JSON.stringify
          gradeables: gradeables
        success: (data) ->
          console.log 'Saved gradeables!'
          res data
      .fail (obj, status) ->
        console.error 'Couldn\'t save gradeables!'
        rej obj
  saveCourse: (data, course_id=null) ->
    console.log "API: saveCourse"
    append = if course_id? then '/' + course_id else ''
    # append += '.json'
    type = if course_id? then 'PUT' else 'POST'
    RavenLogger['type'] = type
    req_data = course: data.course

    @obj = null
    @status = null
    promise = new Promise (res, rej) ->
      $.ajax
        type: type,
        url: '/courses' + append + '.json',
        contentType: 'application/json',
        data: JSON.stringify(req_data)
        success: (data) ->
          res data
      .fail (obj, status) ->
        @obj = obj
        @status = status
        console.error 'Couldn\'t save course!'
        RavenLogger['obj'] = @obj
        RavenLogger['status'] = @status
        Raven.captureMessage('saveCourse failed',
                             level: 'error',
                             extra: RavenLogger)
        rej obj

    promise

  deleteCourse: (course_id) ->
    $.ajax
      type: 'DELETE'
      url: '/courses/' + course_id + '.json'
      success: (data) ->
        window.location = '/'
    .fail (obj, status) ->
        console.error 'Couldn\'t delete course'

  deleteBlock: (block_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'DELETE'
        url: '/blocks/' + block_id + '.json'
        success: (data) ->
          res block_id: block_id
      .fail (obj, status) ->
          console.error 'Couldn\'t delete block'
          rej obj

  deleteWeek: (week_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'DELETE'
        url: '/weeks/' + week_id + '.json'
        success: (data) ->
          res week_id: week_id
      .fail (obj, status) ->
          console.error 'Couldn\'t delete week'
          rej obj

  notifyOverdue: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET'
        url: '/courses/' + course_id + '/notify_untrained.json'
        success: (data) ->
          alert 'Students with overdue trainings notified!'
          res data
      .fail (obj, status) ->
        logErrorMessage(obj, 'Couldn\'t notify students! ')
        rej obj

  submitWizard: (course_id, wizard_id, data) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/wizard/' + wizard_id + '.json',
        contentType: 'application/json',
        data: JSON.stringify
          wizard_output: data
        success: (data) ->
          console.log 'Submitted the wizard answers!'
          res data
      .fail (obj, status) ->
        getErrorMessage(obj, 'Couldn\'t submit wizard answers! ')
        rej obj

  modify: (model, course_id, data, add) ->
    verb = if add then 'added' else 'removed'
    new Promise (res, rej) ->
      $.ajax
        type: (if add then 'POST' else 'DELETE')
        url: "/courses/#{course_id}/#{model}.json"
        contentType: 'application/json',
        data: JSON.stringify data
        success: (data) ->
          console.log (capitalize(verb) + ' ' + model)
          res data
      .fail (obj, status) ->
        logErrorMessage(obj, "#{capitalize(model)} not #{verb}: ")
        rej obj

  onboard: (data) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'PUT'
        url: "/onboarding/onboard"
        contentType: 'application/json'
        data: JSON.stringify data
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  dismissNotification: (id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'PUT'
        url: '/survey_notification'
        dataType: 'json'
        data: { survey_notification: { id: id, dismissed: true }  }
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  uploadSyllabus: ({ courseId, file }) ->
    new Promise (res, rej) ->
      data = new FormData()
      data.append("syllabus", file)
      $.ajax
        type: 'POST'
        cache: false
        url: "/courses/#{courseId}/update_syllabus"
        contentType: false
        processData: false
        data: data
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

  createNeedHelpAlert: (opts) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST'
        url: "/alerts"
        data: opts
        success: (data) ->
          res data
      .fail (obj, status) ->
        logErrorMessage(obj)
        rej obj

module.exports = API
