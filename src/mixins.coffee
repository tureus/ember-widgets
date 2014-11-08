Ember.Widgets.StyleBindingsMixin = Ember.Mixin.create
  concatenatedProperties: ['styleBindings']
  attributeBindings: ['style']
  unitType: 'px'

  createStyleString: (styleName, property) ->
    value = @get property
    return if value is undefined
    if Ember.typeOf(value) is 'number'
      value = value + @get('unitType')
    "#{styleName}:#{value};"

  applyStyleBindings: ->
    styleBindings = this.styleBindings
    return unless styleBindings
    # get properties from bindings e.g. ['width', 'top']
    lookup = {}
    styleBindings.forEach (binding) ->
      [property, style] = binding.split(':')
      lookup[(style or property)] = property
    styles     = _.keys lookup
    properties = _.values lookup

    # create computed property
    styleComputed = Ember.computed =>
      styleTokens = styles.map (style) =>
        @createStyleString style, lookup[style]
      styleString = styleTokens.join('')
      return styleString unless styleString.length is 0
    # add dependents to computed property
    styleComputed.property.apply(styleComputed, properties)
    # define style computed properties
    Ember.defineProperty this, 'style', styleComputed

  init: ->
    @applyStyleBindings()
    @_super()

Ember.Widgets.BodyEventListener = Ember.Mixin.create
  bodyElementSelector: 'html'
  bodyClick: Ember.K

  didInsertElement: ->
    @_super()
    # It is important to setup document handlers in the next run loop.
    # Otherwise we run in to situation whenre the click that causes a popover
    # to appears will be handled right away when we attach a click handler.
    # This very same click will trigger the bodyClick to fire and thus
    # causing us to hide the popover right away
    Ember.run.next this, @_setupDocumentHandlers

  willDestroyElement: ->
    @_super()
    @_removeDocumentHandlers()

  _setupDocumentHandlers: ->
    return if @_clickHandler
    @_clickHandler = (event) =>
      Ember.run =>
        if (@get('_state') or @get('state')) is 'inDOM' and Ember.isEmpty(@$().has($(event.target)))
          @bodyClick()
    $(@get('bodyElementSelector')).on "click", @_clickHandler

  _removeDocumentHandlers: ->
    $(@get('bodyElementSelector')).off "click", @_clickHandler
    @_clickHandler = null

Ember.Widgets.TabbableModal = Ember.Mixin.create

  _focusTabbable: ->
     # Set focus to the first match:
     # 1. First element inside the dialog matching [autofocus]
     # 2. Tabbable element inside the content element
     # 3. The close button (has class "close")
     # 4. The dialog itself
    hasFocus = @$( "[autofocus]" )
    if hasFocus.length == 0
      hasFocus = @$( ":tabbable" )
    if hasFocus.length > 0
      if hasFocus[0].className.indexOf("close") > -1
        # if we have more than two tabbable objects, we do not want to tab to
        # while if we do not have any choice, the close button is chosen
        if hasFocus.length > 1
          hasFocus[1].focus()
          return
      hasFocus[0].focus()

  _keepFocus: (event) ->
    focusable = @$(':focusable')
    isActive = $.contains(@$()[0], event.target)
    if not isActive
      event.preventDefault()
    @_focusTabbable()

  click: (event) ->
    # debugger
    modality = @get 'enforceModality'
    isActive = $.contains(@$()[0], event.target)
    # _currentFocus = $(document.activeElement)[0]
    if modality? and modality == no and not isActive
      @hide() unless @get('enforceModality')
    else if not isActive or $.inArray(event.target, @$(':focusable'))==-1
      @_focusTabbable()

  # capture the TAB key and make a cycle tab loop among the tabbable elements
  # inside the modal. Remove the close button from the loop
  keyDown: (event) ->
    return if event.isDefaultPrevented()

    if event.keyCode == @KEY_CODES.ESCAPE and @get 'escToCancel'
      @doCancelation()
      event.preventDefault()
      event.stopPropagation()
    else if event.keyCode == @KEY_CODES.TAB
      tabbableObjects = @$(":tabbable")
      # remove close button out of tabbable objects list
      _.remove tabbableObjects, (item) ->
        item.className.indexOf("close") > -1

      _currentFocus = $(document.activeElement)?[0]

      if $.inArray(_currentFocus, tabbableObjects) == -1
        @_focusTabbable()

      # if there is no tabbable objects, set focus to the modal
      if (tabbableObjects.length > 0)
        first = tabbableObjects[0]
        last = tabbableObjects[tabbableObjects.length - 1]
        # check the two ends of the array to make it the tab loop
        if (event.target == last and not event.shiftKey)
          first.focus()
          event.preventDefault()
        else if (event.target == first and event.shiftKey)
          last.focus()
          event.preventDefault()
        else
          @_super(event)
      else
        @_super(event)
    else
      @_super(event)
