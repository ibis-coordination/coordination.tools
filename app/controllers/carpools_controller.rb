class CarpoolsController < ApplicationController
  include CarpoolBoard

  before_action :require_user, except: :show
  before_action :set_owned_carpool, only: %i[edit update destroy]
  def new
    @carpool = Carpool.new(starts_at: 1.week.from_now.change(min: 0))
  end

  def create
    @carpool = current_user.carpools.new(carpool_params)
    if @carpool.save
      redirect_to carpool_path(@carpool), notice: "Your carpool is ready to share."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @carpool.update(carpool_params)
      redirect_to carpool_path(@carpool), notice: "Carpool details updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @carpool.destroy!
    redirect_to root_path, notice: "The #{@carpool.name} carpool was deleted."
  end

  def show
    @carpool = Carpool.find_by!(public_id: params[:public_id])
    load_board
  end

  private

  def set_owned_carpool
    @carpool = current_user.carpools.find_by!(public_id: params[:public_id])
  end

  def carpool_params
    params.require(:carpool).permit(:name, :destination, :starts_at, :return_starts_at, :details)
  end
end
