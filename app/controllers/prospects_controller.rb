class ProspectsController < ApplicationController
  before_action :set_prospect, only: %i[ show edit update destroy ]

  # GET /prospects or /prospects.json
  def index
    @prospects = Prospect.all
  end

  # GET /prospects/1 or /prospects/1.json
  def show
  end

  # GET /prospects/new
  def new
    @prospect = Prospect.new
  end

  # GET /prospects/1/edit
  def edit
  end

  # POST /prospects or /prospects.json
  def create
    @prospect = Prospect.new(prospect_params)

    respond_to do |format|
      if @prospect.save
        format.html { redirect_to @prospect, notice: "Prospect was successfully created." }
        format.json { render :show, status: :created, location: @prospect }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @prospect.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /prospects/1 or /prospects/1.json
  def update
    respond_to do |format|
      if @prospect.update(prospect_params)
        format.html { redirect_to @prospect, notice: "Prospect was successfully updated." }
        format.json { render :show, status: :ok, location: @prospect }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @prospect.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /prospects/1 or /prospects/1.json
  def destroy
    @prospect.destroy!

    respond_to do |format|
      format.html { redirect_to prospects_path, status: :see_other, notice: "Prospect was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_prospect
      @prospect = Prospect.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def prospect_params
      params.require(:prospect).permit(:index)
    end
end
