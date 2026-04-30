class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    redirect_to new_session_path if User.exists?
    @user = User.new
  end

  def create
    if User.exists?
      redirect_to new_session_path, alert: "Registration is closed for this instance."
      return
    end

    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Admin account created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end

