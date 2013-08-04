require 'rubygems'
require 'sinatra'
require 'sinatra/content_for'
require 'oauth2'
require 'json'
require 'haml'
require 'net/https'

CLIENT_ID = 'ZF5D2XKPDTKDVTA30L5ZM2FZK3JPKG30AFDSOQMIFJT0UFUJ'
CLIENT_SECRET = 'T0MFLT4CMZREMCXD0MCWWO12JELE2IWVDLTYZA4S3TQ1L5IF'
CALLBACK_PATH = '/session/callback'

def client
	OAuth2::Client.new(
		CLIENT_ID,
		CLIENT_SECRET,
		:site => 'http://foursquare.com/v2/',
		:request_token_path => "/oauth2/request_token",
		:access_token_path => "/oauth2/access_token",
		:authorize_path => "/oauth2/authenticate?response_type=code",
		:parse_json => true
	)
end

def redirect_uri()
	uri = URI.parse(request.url)
	uri.path = CALLBACK_PATH
	uri.query = nil
	uri.to_s
end

get '/session/callback' do
	# access_token = client.web_server.get_access_token(params[:code], :redirect_uri => redirect_uri)
	# It would be better to use the line above but it returns a 301 error, so I use the hack below instead.

	# start hack
	uri = URI.parse("https://foursquare.com/oauth2/access_token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&grant_type=authorization_code&redirect_uri=#{redirect_uri}&code=" + params[:code])
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE

	request = Net::HTTP::Get.new(uri.request_uri)
	response = JSON.parse(http.request(request).body)
	access_token = OAuth2::AccessToken.new(client, response["access_token"])
	# end hack

	# Get user checkins.
	user = access_token.get('https://api.foursquare.com/v2/users/self/checkins')
	user.inspect
end

get '/signin' do
	redirect client.web_server.authorize_url(:redirect_uri => redirect_uri)
end

get '/' do
	haml :index
end
