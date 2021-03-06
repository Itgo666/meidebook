class PostsController < ApplicationController
  get '/new' do
    slim '/posts/new'.to_sym
  end

  post '/' do
    post = Post.new(body: params[:body],
                    user_id: session[:user_id],
                    created_at: Time.now,
                    updated_at: Time.now)

    if post.valid?
      post.save
      redirect '/room'
    else
      flash[:body] = params[:body]
      flash_errors(post)
      redirect '/posts/new'
    end
  end

  # Notice: 请将本方法放在最后，因为“/:id”是泛匹配
  get '/:id' do
    @post = Post.find(id: params[:id], user_id: session[:user_id])
    if @post
      slim :'/posts/show'
    else
      status 404
    end
  end
end