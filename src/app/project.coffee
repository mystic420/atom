fs = require 'fs'
Buffer = require 'buffer'
_ = require 'underscore'
EventEmitter = require 'event-emitter'
Directory = require 'directory'

module.exports =
class Project
  rootDirectory: null
  buffers: null

  constructor: (path) ->
    @setPath(path)
    @buffers = []

  getPath: ->
    @rootDirectory?.path

  setPath: (path) ->
    @rootDirectory?.off()

    if path?
      directory = if fs.isDirectory(path) then path else fs.directory(path)
      @rootDirectory = new Directory(directory)
    else
      @rootDirectory = null

    @trigger "path-change"

  getRootDirectory: ->
    @rootDirectory

  getFilePaths: ->
    fs.async.listTree(@getPath()).pipe (paths) =>
      @relativize(path) for path in paths when fs.isFile(path)

  open: (filePath) ->
    if filePath?
      filePath = @resolve(filePath)
      @bufferWithPath(filePath) ? @buildBuffer(filePath)
    else
      @buildBuffer()

  buildBuffer: (filePath) ->
    buffer = new Buffer(filePath)
    @buffers.push(buffer)
    @trigger 'new-buffer', buffer
    buffer

  resolve: (filePath) ->
    filePath = fs.join(@getPath(), filePath) unless filePath[0] == '/'
    fs.absolute filePath

  relativize: (fullPath) ->
    fullPath.replace(@getPath(), "").replace(/^\//, '')

  bufferWithId: (id) ->
    return buffer for buffer in @buffers when buffer.id == id

  bufferWithPath: (path) ->
    return buffer for buffer in @buffers when buffer.path == path

_.extend Project.prototype, EventEmitter
