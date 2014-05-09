get = (object, key) ->
  return undefined unless object
  return object    unless key
  object.get?(key) or object[key]

set = (object, key, value) ->
  return unless object and key
  object.set?(key, value) or object[key] = value


Ember.Widgets.SelectableItem = Ember.Object.extend
  label: undefined
  value: undefined
  selected: undefined


Ember.Widgets.MultiCheckableComponent = Ember.Widgets.MultiSelectComponent.extend
  selections: []
  templateName: 'multi-checkable'
  selectableItems: Ember.computed ->
    @get('content').map (item) =>
      emberized = Ember.Widgets.SelectableItem.create
        label: get item, @get('optionLabelPath')
        value: get item, @get('optionValuePath')
        selected: item in @get('selections')
  .property 'content.@each'

  # It matches the item label with the query. This can be overrideen for better
  matcher: (searchText, item) ->
    return yes unless searchText
    label = item.get('label')
    escapedSearchText = searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
    regex = new RegExp(escapedSearchText, 'i')
    regex.test(label)

  selectedItemsDidChange: Ember.observer ->
    @set "selections", @get("selectableItems").filter (item) ->
      item.get "selected"
  , 'selectableItems.@each.selected'

  filteredItemControllers: Ember.computed ->
    Ember.ArrayController.create
      content: @get 'filteredContent'
  .property 'filteredContent.@each', 'query'

  filteredContent: Ember.computed ->
    selectableItems = @get 'selectableItems'
    query   = @get 'query'
    return selectableItems unless query
    # don't exclude items that are already selected
    @get('selectableItems').filter (item) =>
      @matcher(query, item)
  .property 'selectableItems.@each', 'query'

  ##############################################################################
  # Overwriting default behavior defined in Ember.Widgets.SelectComponent
  ##############################################################################
  deletePressed: -> Ember.K
  upArrowPressed: -> Ember.K
  downArrowPressed: -> Ember.K
  enterPressed: -> Ember.K
  escapePressed: -> Ember.K
