class UsersController < ApplicationController

  def index
    @users = if params[:search]
      User.where('name LIKE ?', "%#{params[:search]}%")
    else
      User.suggested_friends
    end
  end

  def show
    @user = User.find_by(id: params[:id])
    @post = current_user.posts.build
    @posts = @user.feed
  end

  def update
    if params[:user]
      @user = User.find_by(id: params[:id])
      @user.update_attributes(user_params)
      redirect_to user_path
    else
      flash[:danger] = "You must first pick a file to upload"
      redirect_to user_path
      #redirect_to user_path because the input button gets disabled after error
    end
  end

  private

    def user_params
      params.require(:user).permit(:image, :wallpaper)
    end

end
