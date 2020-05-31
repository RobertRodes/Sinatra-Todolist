require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
end

helpers do
  def complete?(list)
    !list[:todos].empty? && open_todo_count(list).zero?
  end

  def get_todo(id)
    @list[:todos].find { |todo| todo[:id] == id }
  end

  def list_classes(list)
    'complete' if complete?(list)
  end

  def next_list_id(lists)
    (lists.map { |list| list[:id] }.max || -1) + 1
  end

  def next_todo_id(todos)
    (todos.map { |todo| todo[:id] }.max || -1) + 1
  end

  def open_todo_count(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def sorted_lists(lists)
    complete_lists, incomplete_lists =
      lists.partition { |list| complete?(list) }

    incomplete_lists.each { |list| yield list }
    complete_lists.each { |list| yield list }
  end

  def sorted_todos(todos)
    complete_todos, incomplete_todos =
      todos.partition { |todo| todo[:completed] }
    incomplete_todos.each { |todo| yield todo }
    complete_todos.each { |todo| yield todo }
  end

  def todos_count(list)
    list[:todos].size
  end
end

# Apply validation logic, return error message or nil if no error
def error_for_list(name)
  if !(1..100).cover?(name.size)
    'List name must have from 1 to 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name \"#{name}\" is already in use."
  end
end

def error_for_todo(name)
  'Todo name must have from 1 to 100 characters.' unless
    (1..100).cover?(name.size)
end

def load_list(id)
  list = session[:lists].find { |list| list[:id] == id }
  if !list
    session[:error] = "List '#{id}' not found"
    redirect '/lists'
  end
  list
end

get '/' do
  redirect '/lists'
end

# GET   / or /lists     -> view all lists
# GET   /lists/new      -> new list form
# POST  /lists          -> create new list
# GET ` /lists/1        -> view a single list
# GET   /lists/1/edit   -> edit an existing list
# POST  /lists/1        -> update an existing list (save edits)

# View all todo lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Show new todo list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Create a new todo list
post '/lists' do
  @lists = session[:lists]
  list_name = params[:list_name].strip
  error = error_for_list(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @lists << {id: next_list_id(@lists), name: list_name, todos: []}
    session[:success] = "List \"#{list_name}\"successfully added."
    redirect '/lists'
  end
end

# View a single todo list
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:id/edit' do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :edit_list, layout: :layout
end

# Update an existing todo list (save edits)
post '/lists/:id' do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  list_name = params[:list_name].strip
  if list_name == @list[:name]
    redirect "/lists/#{@list_id}"
  else
    error = error_for_list(list_name)
    if error
      session[:error] = error
      erb :edit_list, layout: :layout
    else
      @list[:name] = list_name
      session[:success] = 'List successfully updated.'
      redirect "/lists/#{@list_id}"
    end
  end
end

# Delete a todo list
post '/lists/:id/destroy' do
  @lists = session[:lists]
  list_to_delete = @lists.find { |list| list[:id] == (params[:id].to_i) }
  name = list_to_delete[:name]
  session[:lists].delete(list_to_delete)
  session[:success] = "List \"#{name}\" deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    '/lists'
  else
    redirect '/lists'
  end
end

# Add a new todo to a todo list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_name = params[:todo].strip
  error = error_for_todo(todo_name)
  id = next_todo_id(@list[:todos])
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { id: id, name: todo_name, completed: false }
    session[:success] = "Todo \"#{todo_name}\" added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a todo list
post '/lists/:list_id/todos/:todo_id/destroy' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i
  todo = get_todo(todo_id)
  @list[:todos].delete_if { |todo| todo[:id] == todo_id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    redirect "/lists/#{@list_id}"
  end
end

# Complete or uncomplete a todo
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i
  todo = get_todo(todo_id)
  todo[:completed] = params[:completed] == 'true'
  session[:success] = "All \"#{@list[:name]}\"todos completed." if
    complete?(@list)
  redirect "/lists/#{@list_id}"
end

# Complete all todos
post '/lists/:list_id/complete_all_todos' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All \"#{@list[:name]}\"todos completed."
  redirect "/lists/#{@list_id}"
end
