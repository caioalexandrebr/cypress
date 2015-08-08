_        = require 'lodash'
Promise  = require 'bluebird'
Request  = require 'request-promise'
fs       = require 'fs'
path     = require 'path'
Log      = require "./log"
Settings = require './util/settings'
Routes   = require './util/routes'

fs       = Promise.promisifyAll(fs)


class Project
  constructor: (projectRoot) ->
    if not (@ instanceof Project)
      return new Project(projectRoot)

    if not projectRoot
      throw new Error("Instantiating lib/project requires a projectRoot!")

    @projectRoot = projectRoot

  ## A simple helper method
  ## to create a project ID if we do not already
  ## have one
  ensureProjectId: ->
    @getProjectId()
    .bind(@)
    .catch(@createProjectId)

  createProjectId: ->
    Log.info "Creating Project ID"

    require("./cache").getUser().then (user = {}) =>
      Request.post({
        url: Routes.projects()
        headers: {"X-Session": user.session_token}
      })
      .then (attrs) =>
        attrs = {projectId: JSON.parse(attrs).uuid}
        Log.info "Writing Project ID", _.clone(attrs)
        Settings.write(@projectRoot, attrs)
      .get("projectId")

  getProjectId: ->
    Settings.read(@projectRoot)
    .then (settings) ->
      if (id = settings.projectId)
        Log.info "Returning Project ID", {id: id}
        return id

      Log.info "No Project ID found"
      throw new Error("No project ID found")

  getDetails: (projectId) ->
    require("./cache").getUser().then (user = {}) =>
      Request.get({
        url: Routes.project(projectId)
        headers: {"X-Session": user.session_token}
      }).catch (err) ->
        ## swallow any errors

module.exports = Project