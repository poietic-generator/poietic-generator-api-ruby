#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'erb'
require 'sass'

# FIXME:
# lancer un timer qui nettoie les participants déconnectés
# toutes les 300 secondes

class GenP < Sinatra::Base
	set :static, true
	set :public, File.dirname(__FILE__) + '/static'

	get '/' do 
		erb :index
		#"Hello world"
	end

	get '/session/join' do
		# creer une session
		# on attribue un id 'participant' au client
		erb :session
	end

	get '/session/update' do
		# le participant <user-id> doit renouveller son bail avant 300
		# secondes sinon on le considere déconnecté
	end

	get '/session/:idx/join' do 
		# joindre une session
		# rediriger vers la session
	end

end
# un moyen d'envoyer un paquet de données
#
# recevoir le dernier paquet de données depuis la date X
# 
