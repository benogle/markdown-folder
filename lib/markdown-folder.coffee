{CompositeDisposable, Point, Range, TextBuffer} = require 'atom'

module.exports = MarkdownFolder =
  subscriptions: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-folder:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-folder:foldall-h1': => @foldall(/^(#+)/)
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-folder:foldall-h2': => @foldall(/^(##+)/)
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-folder:foldall-h3': => @foldall(/^(###+)/)
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-folder:foldall-h4': => @foldall(/^(####+)/)
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-folder:foldall-h5': => @foldall(/^(#####+)/)
    @subscriptions.add atom.commands.add 'atom-workspace', 'markdown-folder:unfoldall': => @unfoldall()

  deactivate: ->
    @subscriptions.dispose()

  toggle: ->
    @folderer('toggle', -1)

  foldall: (matcher) ->
    editor = atom.workspace.getActiveTextEditor()
    for linenumber in [editor.getLastBufferRow()..0]
      linetext = editor.lineTextForBufferRow(linenumber)
      if linetext.match(matcher)
        @folderer('fold', linenumber)

  unfoldall: ->
    editor = atom.workspace.getActiveTextEditor()
    editor.unfoldAll()

  getNextMatcher: (matcher) ->
    result = /^#\s/
    switch matcher.length
      when 2 then result = /^#\s|^##\s/
      when 3 then result = /^#\s|^##\s|^###\s/
      when 4 then result = /^#\s|^##\s|^###\s|^####\s/
      when 5 then result = /^#\s|^##\s|^###\s|^####\s|^#####\s/
      when 6 then result = /^#\s|^##\s|^###\s|^####\s|^#####\s|^######\s/
    return result

  folderer: (action, startrow) ->
    editor = atom.workspace.getActiveTextEditor()

    if startrow == -1
      startrow = editor.getCursorBufferPosition().row

    if action == 'toggle'
      if editor.isFoldedAtBufferRow(startrow + 1)
        action = 'unfold'
      else
        action = 'fold'

    linetext = editor.lineTextForBufferRow(startrow)
    thematch = linetext.match(/^(#+)/)
    nextmatchfound = false

    if thematch
      lastrowindex = editor.getLastBufferRow()
      lastrowtext = editor.lineTextForBufferRow(lastrowindex)
      nextmatch = @getNextMatcher(thematch[1])
      searchrange = new Range(new Point(startrow + 1 , 0), new Point(lastrowindex,lastrowtext.length - 1))

      toggleFold = (range) ->
        if action == 'unfold'
          for row in [startrow..range.end.row - 1]
            editor.unfoldBufferRow(row)
        else
          # Don't fold empty lines. Go backwards and check
          lastrowtofold = range.end.row - 1
          for linenr in [lastrowtofold..startrow + 1]
            if editor.lineTextForBufferRow(linenr).match(/^\s*$/) # only whitespace
              lastrowtofold--
            else
              break
          editor.setSelectedBufferRange(new Range(new Point(startrow, 0), new Point(lastrowtofold, 0)))
          editor.foldSelectedLines()
        editor.setCursorBufferPosition(new Point(startrow, 0))

      scanCallback = (scanresult) ->
        toggleFold(scanresult.range)
        nextmatchfound = true

      editor.scanInBufferRange(nextmatch, searchrange, scanCallback)

      if !nextmatchfound
        toggleFold(new Range(new Point(startrow, 0),new Point(lastrowindex,lastrowtext.length - 1)))
