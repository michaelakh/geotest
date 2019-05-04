class OfficesController < ApplicationController
  before_action :set_office, only: [:show, :edit, :update, :destroy]

  def index
    @offices = Office.all
  end

  def show
    
  end
  
  def search
    if params['postcode'] == ''
      flash[:alert] = 'please enter a postcode'
      redirect_to offices_path
    else
      #get postcode string and take out any white space in the string
      postcode = params['postcode'].gsub(/\W/, '')
      
      #use http to make a api request to get lat and long for postcode given
      #return error if non is passed
      
      @request = HTTP.get("http://api.postcodes.io/postcodes/#{postcode}")
      @response = JSON.parse(@request)

      #if postcode passed isn't a outcode, then try http request as regular postcode
      if @response['status'] != 200
        @request = HTTP.get("http://api.postcodes.io/outcodes/#{postcode}")
        @response = JSON.parse(@request)
      end
      
      if @response['status'] != 200
        flash[:notice] = 'postcode is invalid, please try again'
        redirect_to offices_path
      else
          #set long and lat in params based off values returned from api
        lon = @response['result']['longitude']
        lat = @response['result']['latitude']

        distance = params['distance'].to_i * 1609.34

        # This query doesn't return Distance as part of the active record object
        # @office = Office.where("ST_Distance(lonlat, 'POINT(#{lon} #{lat})') < #{distance}").first(20)

        # So i used raw sql to do so
        sql = "select * from (
        SELECT  *,( ST_Distance(lonlat, 'POINT(#{lon} #{lat})')) AS distance 
        FROM offices
        ) al
        where distance < #{distance}
        ORDER BY distance;"

        @office = ActiveRecord::Base.connection.execute(sql).values.paginate(page: params[:page], per_page: 1)
        # I tested this method with Postgis/rgeo method and they both return almost identical values
      end
      
    end
  end

  def new
    @office = Office.new
  end
  


  def edit
  end

  def create
    @office = Office.new(office_params)
    if @office.valid?
      get_coordinates
      capitalize_params
    end
    @office = Office.new(office_params)
    
    respond_to do |format|
      if @office.save
        format.html { redirect_to @office, notice: 'Office was successfully created.' }
        format.json { render :show, status: :created, location: @office }
      else
        format.html { render :new }
        format.json { render json: @office.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    get_coordinates
    capitalize_params
    respond_to do |format|
      if @office.update(office_params)
        format.html { redirect_to @office, notice: 'Office was successfully updated.' }
        format.json { render :show, status: :ok, location: @office }
      else
        format.html { render :edit }
        format.json { render json: @office.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @office.destroy
    respond_to do |format|
      format.html { redirect_to offices_url, notice: 'Office was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_office
      @office = Office.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def office_params
      params.require(:office).permit(:name, :country, :postcode, :street_ad, :town_city, :phone_no, :county, :lonlat)
    end
  
    def get_coordinates
    # dependicies, needs a valid params['office']['postcode'] value to work
    # get postcode string and take out any white space in the string
      
      postcode = params['office']['postcode'].split(/\W/).join
    
    #use http to make a api request to get lat and long for postcode given
    #return error if non is passed
    @request = HTTP.get("http://api.postcodes.io/postcodes/#{postcode}")
    @response = JSON.parse(@request)
    
    #set long and lat in params based off values returned from api
    params['office']['lonlat'] = "POINT(#{@response['result']['longitude']} #{@response['result']['latitude']})"
      
    end
  
  def capitalize_params
    params['office']['name'].capitalize!
    params['office']['postcode'].upcase! 
    params['office']['county'].capitalize! 
    params['office']['town_city'].capitalize! 
     
  end
end
