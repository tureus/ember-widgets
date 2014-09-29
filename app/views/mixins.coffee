App.CodePrettyPrintMixin = Ember.Mixin.create
  didInsertElement: ->
    @_super()
    Ember.run.next this, -> prettyPrint()

App.LargeHeroAffixMixin = Ember.Mixin.create
  didInsertElement: ->
    @_super()

App.SmallHeroAffixMixin = Ember.Mixin.create
  didInsertElement: ->
    @_super()
