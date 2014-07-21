Ember.Widgets.SelectableItemController = Ember.ObjectController.extend
  content: null
  disabled: Ember.computed.alias 'parentController.selectAllOrDisabled'

  selected: Ember.computed (key, value) ->
    return yes if @get('parentController.selectAll')
    selections = @get 'parentController.selections'
    return no unless selections
    itemValue = @get 'value'
    if arguments.length > 1
      if value
        selections.addObject itemValue
      else
        selections.removeObject itemValue

    selections.contains itemValue
  .property 'parentController.selections.[]', 'parentController.selectAll'

  label: Ember.computed ->
    Ember.get @get('content'), @get('parentController.optionLabelPath')
  .property 'content', 'parentController.optionLabelPath'

  value:  Ember.computed ->
    valuePath = @get 'parentController.optionValuePath'
    content = @get 'content'
    if valuePath
      return Ember.get content, @get('parentController.optionValuePath')
    return content
  .property 'content', 'parentController.optionValuePath'


Ember.Widgets.SelectableItemArrayController = Ember.ArrayController.extend
  optionLabelPath: ''
  optionValuePath: ''
  selections: undefined
  selectAll: undefined
  disabled: undefined
  selectAllOrDisabled: Ember.computed.or 'selectAll', 'disabled'

  controllerAt: (idx, object, controllerClass) ->
    container = @get 'container'
    subControllers = @get '_subControllers'
    subController = subControllers[idx]

    return subController if subController
    subController = @get('itemController').create
      target: this
      parentController: @get('parentController') or this
      content: object
    subControllers[idx] = subController;
    return subController;


Ember.Widgets.MultiCheckableComponent =
Ember.Widgets.MultiSelectComponent.extend
  layoutName: 'multi_check_layout'
  classNames: ['multi-checkable']

  selections: Ember.computed ->
    []
  .property()
  disabled: no
  # NOTE(edward): Implementing the logic for this maybe depends on the item view
  # class, so punt on implementing it for MultiSelectComponent
  selectAll: no

  sortProperties: Ember.computed ->
    [@get 'optionLabelPath']
  .property 'optionLabelPath'

  selectableItems: Ember.computed ->
    Ember.Widgets.SelectableItemArrayController.create
      target: this
      itemController: Ember.Widgets.SelectableItemController
      content: @get('content')
      container: @get('container')
      component: this
      sortPropertiesBinding: 'component.sortProperties'
      sortAscending: true
      optionLabelPathBinding: 'component.optionLabelPath'
      optionValuePathBinding: 'component.optionValuePath'
      selectionsBinding: 'component.selections'
      disabledBinding: 'component.disabled'
      selectAllBinding: 'component.selectAll'
  .property()

  # This is done so when you uncheck selectAll, everything is still checked.
  selectAllDidChange: Ember.observer ->
    if @get 'selectAll'
      @set 'query', ''

    # When we uncheck selectAll, that means selectAll was true.
    # The UI flow is that if selectAll is true and you change it to false,
    # you start with all clients checked. So put all entities in selections.
    # NOTE(edward): The reason we need this code is because selections
    # is reset to empty array by the server.
    selections = @get 'selections'
    items = @get 'selectableItems'
    selections.addObjects items.getEach('value')
  , 'selectAll'

  # It matches the item label with the query. This can be overridden for better
  # matching.
  matcher: (searchText, item) ->
    return yes unless searchText
    label = item.get('label')
    # Regex taken from Ember.Widgets.SelectComponent
    escapedSearchText = searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
    regex = new RegExp(escapedSearchText, 'i')
    regex.test(label)

  filteredContent: Ember.computed ->
    selectableItems = @get 'selectableItems'
    query = @get 'query'
    return selectableItems unless query
    # don't exclude items that are already selected
    selectableItems.filter (item) =>
      @matcher(query, item)
  .property 'selectableItems.@each', 'query'

  actions:
    selectAll: ->
      selections = @get 'selections'
      items = @get 'selectableItems'
      selections.addObjects items.getEach('value')

    deselectAll: ->
      selections = @get 'selections'
      selections.clear()

  ##############################################################################
  # Overwriting default behavior defined in Ember.Widgets.SelectComponent
  ##############################################################################
  deletePressed: -> Ember.K
  upArrowPressed: -> Ember.K
  downArrowPressed: -> Ember.K
  enterPressed: -> Ember.K
  escapePressed: -> Ember.K
