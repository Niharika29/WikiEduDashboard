React = require 'react'
TrainingStore = require '../stores/training_store.coffee'
ServerActions = require('../../actions/server_actions.js').default

getState = ->
  training_module: TrainingStore.getTrainingModule()

TrainingModuleHandler = React.createClass(
  displayName: 'TraniningModuleHandler'
  mixins: [TrainingStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  componentWillMount: ->
    module_id = document.getElementById('react_root').getAttribute('data-module-id')
    ServerActions.fetchTrainingModule(module_id: module_id)
  render: ->
    slidesAry = _.compact(@state.training_module.slides)
    slides = slidesAry.map (slide, i) =>
      disabled = !slide.enabled
      link = "#{@state.training_module.slug}/#{slide.slug}"
      liClassName = 'disabled' if disabled
      if slide.summary
        summary = <div className="ui-text small sidebar-text">{slide.summary}</div>

      <li className={liClassName} key={i}>
        <a disabled={disabled} href={disabled && 'javascript:void(0)' || link}>
          <h3 className="h5">{slide.title}</h3>
          {summary}
        </a>
      </li>

    <div className="training__toc-container">
      <h1 className="h4 capitalize">Table of Contents <span className="pull-right total-slides">({slidesAry.length})</span></h1>
      <ol>
      {slides}
      </ol>
    </div>
)

module.exports = TrainingModuleHandler
