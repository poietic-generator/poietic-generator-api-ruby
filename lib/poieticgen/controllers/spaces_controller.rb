# -*- coding: utf-8 -*-

require 'poieticgen'
require 'singleton'

module PoieticGen
  class SpacesController < ApplicationController
    include Singleton


		# List available session for joining
		def index(ev, req, res)
			@spaces = BoardGroup.all(
				closed: false,
				order: [:id.asc]
			) || []

			res.json({spaces: @spaces.map(&:to_h) })
		end

  end

  module SpacesRoutes
    def self.registered(app)
      app.get('/hop') { SpacesController.instance.index(env, request, response) }
    end
  end
end


