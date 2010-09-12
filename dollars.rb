require 'rubygems'
require 'bundler'
Bundler.setup

require 'sinatra'
require 'dm-core'
require 'dm-migrations'

enable :sessions

DataMapper.setup(:default, 'postgres://localhost:5432/dollars')

class User
  include DataMapper::Resource
  
  has n, :pots

  property :id,           Serial
  property :username,     String
  property :password,     String
  property :cash_money,   Integer
end

class Pot
  include DataMapper::Resource
  
  belongs_to :user
  has n, :contributions
  
  property :id,           Serial
  property :name,         String
  property :cash_money,   Integer
  property :task,         String
  property :user_id,      Integer
  property :reserved_by,  Integer
  property :claimed_by,   Integer
  property :completed_by, Integer
  property :eta,          DateTime
  property :approved_at,  DateTime
end

class Contribution
  include DataMapper::Resource
  
  belongs_to :pot
  
  property :id,       Serial
  property :user_id,  Integer
  property :amount,   Integer
end

DataMapper.finalize
DataMapper.auto_upgrade!

before do
  @user = User.get(session[:user])
end

get '/' do
  authenticate!
  erb :home
end

get '/login' do
  erb :login
end

post '/login' do
  user = User.first(:username => params[:username], :password => params[:password])
  session[:user] = user.id
  redirect '/'
end

get '/new_user' do
  'Create a new account:
  <form action="/new_user" method="post">
  Username: <input type="text" name="username" /><br />
  Password: <input type="password" name="password" />
  </form>'
end

post '/new_user' do
  user = User.first_or_create(:username => params[:username], :password => params[:password])
  user.update(:cash_money => 100) if !user.cash_money
  redirect '/login'
end

get '/all_accounts' do
  User.all.inspect
end

get '/pots' do
  erb :pots
end

get '/create_pot' do
  erb :create_pot
end

post '/create_pot' do
  Pot.create(:name => params[:name], :task => params[:task], :cash_money => params[:cash_money], :user_id => session[:user])
  redirect '/'
end

get '/leaderboard' do
  erb :leaderboard
end

get '/pots/:pot_id/claim_pot' do
  Pot.get(params[:pot_id]).update(:claimed_by => session[:user])
  redirect '/pots'
end

get '/pots/:pot_id/reserve_pot' do
  erb :reserve_pot
end

post '/pots/:pot_id/reserve_pot' do
  eta = DateTime.parse("#{params[:date]} #{params[:time]}").to_s
  redirect "/pots/#{params[:pot_id]}/reserve_pot"
  #Pot.get(params[:pot_id]).update(:reserved_by => session[:user], :eta => params[:eta])
end

def authenticate!
  if session[:user]
    true
  else
    redirect '/login'
  end
end