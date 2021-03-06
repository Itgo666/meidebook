class RootController < ApplicationController
  before /^\/(settings|room)$/ do
    unless logged?
      flash[:notice] = I18n.t('user.not_login_yet')
      redirect '/'
    end
  end

  get '/' do
    slim :index
  end

  get '/about' do
    slim :about
  end

  get '/about2' do
    slim :about2
  end

  get '/please_login' do
    flash[:notice] = '请先免注册、免密码登录！登录后，就可以认领你的书了。'
    redirect '/'
  end

  post '/simple_login' do
    @user = User.find(username: params[:username])
    if @user.nil?
      user = User.new(username: params[:username], domain: User.default_domain, password: Digest::SHA1.hexdigest(''), created_at: Time.now, updated_at: Time.now)
      if user.valid?
        user.save
        login_and_redirect(user)
      else
        flash[:username] = params[:username]
        flash_errors(user)
        redirect '/'
      end
    else
      if @user.password == Digest::SHA1.hexdigest('')
        login_and_redirect(@user)
      else
        flash[:username] = params[:username]
        flash[:notice] = I18n.t('user.please_input_password')
        redirect '/login'
      end
    end
  end

  get '/register' do
    slim :register
  end

  get '/login' do
    slim :login
  end

  post '/do_login' do
    @user = User.find(username: params[:username])

    if @user.nil?
      flash[:error] = I18n.t('user.username_not_exist')
      flash[:username] = params[:username]
      redirect '/login'
    else
      if @user.password == Digest::SHA1.hexdigest(params[:password])
        set_login_session(@user)
        flash[:notice] = I18n.t('user.login_finished')
        redirect '/room'
      else
        flash[:error] = I18n.t('user.password_not_match')
        flash[:username] = params[:username]
        redirect '/login'
      end
    end
  end

  get '/logout' do
    clear_session

    flash[:notice] = I18n.t('user.logout_success')
    redirect '/'
  end

  get '/settings' do
    slim :'/users/settings'
  end

  get '/room' do
    @posts = current_user.posts_dataset.reverse_order(:id)
    slim :room
  end

  get '/captcha' do
    content_type :png
    session[:captcha] = Captcha.random_text
    Captcha.create(session[:captcha])
  end

  post '/submit_captcha' do
    if params[:captcha].downcase == session[:captcha].to_s.downcase
      add_received_books(params[:book_code])
    else
      flash[:error] = I18n.t(:captcha_not_match)
    end

    redirect "/#{params[:book_code]}"
  end

  # Notice: 用于开发人员调试
  get '/clear_received_books_session' do
    session[:received_books] = nil
    flash[:notice] = I18n.t(:operate_success)
    redirect '/'
  end

  get '/u/:domain' do
    @user = User.find(domain: params[:domain])
    if @user
      slim :'/books/user_donated'
    end
  end

  # Notice: 本get始终放在最后
  get '/:book_code' do
    @book = Book.find(code: params[:book_code])

    if @book
      if it_is_me?(@book.user) || session[:received_books].to_s.split(' ').include?(params[:book_code])
        slim :'/books/show'
      else
        slim :'/books/show_captcha'
      end
    else
      slim :'/books/new'
    end
  end

  private

  def login_and_redirect(user)
    set_login_session(user)
    flash[:notice] = I18n.t('user.login_finished_with_username', w: user.username)
    redirect '/settings'
  end
end