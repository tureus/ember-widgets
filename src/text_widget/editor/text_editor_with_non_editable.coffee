Ember.Widgets.TextEditorWithNonEditableComponent =
Ember.Widgets.TextEditorComponent.extend Ember.Widgets.PillInsertMixin,
  layoutName: 'text-editor-with-non-editable'

  ##############################################################################
  # Interface
  ##############################################################################
  pillOptions: Ember.A [
    Ember.Widgets.TodaysDatePill
    Ember.Widgets.NonEditableTextPill
  ]
  getInsertSelectController: -> @get('pillChooserInLine')
  INVISIBLE_CHAR:   '\uFEFF'
  INSERT_PILL_CHAR: '='
  insertPillRegex: Ember.computed ->
    new RegExp @INSERT_PILL_CHAR + '[A-Za-z0-9_\+\-]*$', 'gi'
  .property ('INSERT_PILL_CHAR')

  ##############################################################################
  # Properties
  ##############################################################################
  pillId:           0
  mouseDownTarget:  null
  pillHideSearchBox: false
  showConfigPopover: false
  selectedPillOption: null

  _getElementFromPill: (pill) ->
    pillId = pill.get('params.pillId')
    @getEditor().find('.non-editable[data-pill-id="' + pillId + '"]')

  # gets the html representation of the editor and removes the content
  # of its non-editable pill components
  serialize: ->
    raw_html = @getEditor().html()
    div = $('<div/>').html(raw_html)
    $('.non-editable', div).empty()
    return div.html()

  updateNonEditablePillContent: ->
    pillElements = @getEditor().find('.non-editable[data-pill-id]')
    for pillElement in pillElements
      pill = @_getPillFromElement(pillElement)
      return unless pill
      $(pillElement).text(pill.result())

      # have to make sure to set the contenteditable to false because we
      # don't serialize this stuff properly
      $(pillElement).attr('contenteditable': "false")

  _getPillFromElement: (pillElement) ->
    # Deserialize the pillElement into a pill object
    data = $(pillElement).data()
    return unless data.type
    params = {}
    for key, value of data
      params[key] = value
    Ember.get(data.type).create({'textEditor': this, 'params': params})

  getNewPillId: ->
    @incrementProperty 'pillId'

  updatePill: (pill) -> pill.update()

  insertPill: (pill) ->
    precedingCharacters = @getCharactersPrecedingCaret(@getEditor()[0])
    matches = precedingCharacters.match @get('insertPillRegex')
    if matches
      # Inserting via key, so we need to replace the characters before
      @deleteCharactersPrecedingCaret(matches[0].length, false)

    # Ensure that we insert the factor in the text editor (move the range inside the editor if
    # not already)
    range = @getCurrentRange()
    if not range or not @inEditor(range)
      if not (range = @getCurrentRange()) or not @inEditor(range)
        @selectElement(@getOrCreateLastElementInEditor())
      range = @getCurrentRange()

    existingNonEditable = @_getNonEditableParent(range.startContainer) || @_getNonEditableParent(range.endContainer)
    existingNonEditable?.remove()
    factor = @insertElementAtRange(range, pill.render())

    # Move cursor
    @_moveSelection()

    # Wrap text in div
    @_wrapText()

    # select the caret container again (which has probably been moved)
    @getEditor().focus()

  _isNonEditable: (node) ->
    not Ember.isEmpty($(node).closest('.non-editable'))

  # Get the non editable node, if any, to the left of the current range
  # Node: https://developer.mozilla.org/en-US/docs/Web/API/Node
  # Range: https://developer.mozilla.org/en-US/docs/Web/API/range
  _getNonEditableOnLeft: (deep=false) ->
    return unless (currentRange = @getCurrentRange()) and leftNode = @getNonEmptySideNode(currentRange, true, deep)

    if currentRange.startOffset == 0 && @_isNonEditable(leftNode)
      return leftNode
    else if currentRange.startOffset == 1 && @_isNonEditable(leftNode) and
    currentRange.startContainer.nodeValue?.charAt(0) == @INVISIBLE_CHAR
      # i.e. we are in a non-editable caret container
      return leftNode

  # Get the non editable node, if any, to the right of the current range
  # Node: https://developer.mozilla.org/en-US/docs/Web/API/Node
  # Range: https://developer.mozilla.org/en-US/docs/Web/API/range
  _getNonEditableOnRight: (deep=false) ->
    return unless (currentRange = @getCurrentRange()) and rightNode = @getNonEmptySideNode(currentRange, false, deep)

    endContainer = currentRange.endContainer
    if currentRange.endOffset == endContainer.length && @_isNonEditable(rightNode)
      return rightNode
    else if currentRange.endOffset == endContainer.length - 1 and
    endContainer.nodeValue.charAt(endContainer.nodeValue.length - 1) == @INVISIBLE_CHAR and
    @_isNonEditable(rightNode)
      return rightNode

  _isRangeWithinNonEditable: (range) ->
    $startNode = $(range.startContainer.parentNode)
    $endNode = $(range.endContainer.parentNode)
    $startNode.hasClass('non-editable') && $endNode.hasClass('non-editable') && $startNode[0] == $endNode[0]

  _getNonEditableParent: (node) ->
    while node
      if $(node).hasClass('non-editable')
        return node
      node = node.parentElement

  _moveSelection: ->
    return unless currentRange = @getCurrentRange()

    isCollapsed = currentRange.collapsed
    nonEditableStart = @_getNonEditableParent(currentRange.startContainer)
    nonEditableEnd = @_getNonEditableParent(currentRange.endContainer)

  _showPillConfig: (query) ->
    @set 'showConfigPopover', true
    @set 'pillHideSearchBox', true
    @set 'query', query

  _hidePillConfig: ->
    @set 'showConfigPopover', false
    @set 'pillHideSearchBox', false
    @set 'query', null

  _handlePillConfig: ->
    # Show or hide the pill config component depending on the characters
    # preceding the cursor
    precedingCharacters = @getCharactersPrecedingCaret(@getEditor()[0])
    matches = precedingCharacters.match @get('insertPillRegex')
    if matches
      query = matches[0].split(" ").reverse()[0].slice(1)
      @_showPillConfig(query)
    else
      @_hidePillConfig()

  keyDown: (event) ->
    return unless @isTargetInEditor(event)

    keyCode = event.keyCode

    if @showConfigPopover
      insertSelect = @getInsertSelectController()
      if keyCode == @KEY_CODES.DOWN
        return insertSelect.downArrowPressed(event)
      else if keyCode == @KEY_CODES.UP
        return insertSelect.upArrowPressed(event)
      else if keyCode in [@KEY_CODES.ENTER, @KEY_CODES.TAB] and insertSelect.get('preparedContent').length > 0
        return insertSelect.enterPressed(event)
      else if keyCode == @KEY_CODES.ESCAPE
        return insertSelect.escapePressed(event)

    @_moveSelection()

  _wrapText: ->
    # move things around so that all text are within divs
    # This can only happen on mouse up and key up so that font style selections
    # are saved
    $editor = @getEditor()
    savedSelection = rangy.saveSelection(@_getIframe().contentWindow)
    contents = $editor.contents()
    @wrapInDiv(contents)
    rangy.restoreSelection(savedSelection)

  keyUp: (event) ->
    return unless @isTargetInEditor(event)
    @_moveSelection()
    @_wrapText()

    unless event.keyCode == @KEY_CODES.ESCAPE
      @_handlePillConfig()
      @_super()

  mouseDown: (event) ->
    return unless @isTargetInEditor(event)
    @mouseDownTarget = event.target  # Save mousedown target for use in mouseup handler
    @_moveSelection()

  mouseUp: (event) ->
    return unless @isTargetInEditor(event)
    @_moveSelection()  # expand selection if only part of a non-editable was selected
    @_wrapText()

    currentRange = @getCurrentRange()
    if @_isNonEditable(event.target) and @_isRangeWithinNonEditable(currentRange)
      # This prevents the user from putting the cursor within a non-editable that was previously selected
      @selectElement(event.target, "none") 
      console.log(window.getSelection())
      event.preventDefault()
    @_super()

  click: (event) -> Ember.K
