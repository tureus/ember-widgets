Ember.Widgets.NonEditableTextPill = Ember.Widgets.BaseNonEditablePill.extend
  name: "Custom Text"
  text: Ember.computed.alias 'params.text'

  result: ->
    @get('params.text')

  configure: ->
    modal = Ember.Widgets.ModalComponent.popup
      content: this
      targetObject: this
      confirm: "modalConfirm"
      cancel: "modalCancel"
      contentViewClass: Ember.View.extend
        templateName: 'non-editable-text-pill-configuration'
      headerText: @get('name')
      confirmText: "Insert"

