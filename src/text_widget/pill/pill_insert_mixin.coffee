Ember.Widgets.PillInsertMixin = Ember.Mixin.create
  pillOptions: Ember.A [
    Ember.Widgets.TodaysDatePill
    Ember.Widgets.NonEditableTextPill
  ]

  _pillOptions : Ember.computed ->
    Ember.A @getWithDefault('pillOptions', []).map (option) =>
      label: option.create().name
      value: option
  .property 'pillOptions'

  actions:
    insertPill: (pillOption) ->
      selectedPillOption = pillOption.value.create textEditor: @get('textEditor') or this
      selectedPillOption.configure()
      @set 'selectedPillOption', null

