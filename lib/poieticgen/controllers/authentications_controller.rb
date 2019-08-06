# -*- coding: utf-8 -*-

require 'poieticgen'
require 'singleton'

module PoieticGen
  module AuthenticationsRoutes
    def registered(app)
      app.get('/login') { AuthenticationsController.instance(app).login }
      app.post('/logout') { AuthenticationsController.instance(app).logout }
      app.post('/signup') { RegistrationController.instance(app).signup }
      app.post('/:id') { RegistrationController.instance(app).show }

		  app.post '/user/login' do 
			  begin
				  admin_token = settings.manager.admin_join params
				  redirect '/session/admin?admin_token=%s' % admin_token

			  rescue PoieticGen::AdminSessionNeeded => e
				  flash[:error] = "Invalid username or password"
				  redirect '/user/login'

			  rescue Exception => e
				  STDERR.puts e.inspect, e.backtrace
				  Process.exit! #FIXME: remove in prod mode ? :-)
			  end
		  end

		  app.get '/user/logout' do
			  settings.manager.admin_leave params
			  # redirect '/'
			  { }
		  end
    end
  end

  class AuthenticationsController < ApplicationController
    include Singleton

    def login
    end

    def logout
    end
		
		def admin_join params
			req_name = params[:user_name]
			req_password = params[:user_password]

			# FIXME: prevent session from being stolen...
			STDERR.puts "requesting name=%s" % req_name

			is_admin = if req_password.nil? or req_name.nil? then false
			           else req_password == @config.server.admin_password and
			                req_name == @config.server.admin_username
			           end

			raise AdminSessionNeeded, "Invalid parameters." if not is_admin

			admin = Admin.first(name: req_name)
			if admin.nil? then
				admin = Admin.create req_name, @config.user
			else
				admin.report_expiration @config.user
			end

			return admin.token
		end

		def admin_leave params
			req_token = params[:admin_token]
			admin = Admin.first(token: req_token)

			unless admin.nil? then
				admin.set_expired
			end
		end

		def admin? params
			req_token = params[:admin_token]
			admin = Admin.first(token: req_token)

			return (!admin.nil? and !admin.expired?)
		end

  end
end

