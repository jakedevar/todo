require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @lists = session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = session[:lists]

  erb :lists
end

get '/lists/new' do
  erb :new_list
end

get "/lists/:number" do 
  @ind = params[:number].to_i
  redirect "/lists" if to_big?(@lists, @ind)
  erb :list_of_todos
end

get "/lists/:number/edit" do 
  @ind = params[:number].to_i
  @list = @lists[@ind]
  erb :edit_todo
end

post "/lists/:number/edit" do 
  @ind = params[:number].to_i
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :edit_todo
  else
    session[:lists][@ind][:name] = list_name
    session[:success] = 'The list has been edited.'
    redirect '/lists'
  end
end

post "/lists/:number/delete" do 
  @ind = params[:number].to_i
  session[:lists].delete_at(@ind)
  session[:success] = "The list has been deleted"
  redirect "/lists"
end

def error_for_list_name(name)
  if !(1..100).cover? name.size
    'The list name must be between 1-100 characters'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be uniqe'
  end
end

post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    'The Todo must be between 1-100 characters'
  end
end

post "/lists/:number" do 
  @ind = params[:number].to_i
  @list = session[:lists][@ind]
  text = params[:todo].strip 

  error = error_for_todo(text)
  if error 
    session[:error] = error
    erb :list_of_todos
  else
    @list[:todos] << {name: text, completed: false}
    session[:success]
    redirect '/lists/:number'
  end
end

post "/delete/:number/:ind" do 
  ind = params[:ind].to_i
  num = params[:number].to_i
  @list = session[:lists][num]
  @list[:todos].delete_at(ind)
  redirect "lists/:number"
end



post "/check/:number/:ind" do 
  ind = params[:ind].to_i
  num = params[:number].to_i
  @list = session[:lists][num]
  @list[:todos][ind][:completed] = !@list[:todos][ind][:completed]
  session[:success] = "The todo has been updated"
  redirect "lists/:number"
end

post "/complete-all/:number" do 
  num = params[:number].to_i
  @list = session[:lists][num]
  @list[:todos].each do |todo_hsh|
    todo_hsh[:completed] = true
  end

  session[:success] = "All todos have been completed"
  redirect "lists/:number"
end

helpers do 
  def all_complete?(list)
    list[:todos].all? { |todo| todo[:completed] }
  end
end

def to_big?(list, n)
  n > list.size   
end

