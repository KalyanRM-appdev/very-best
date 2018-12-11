class VenuesController < ApplicationController
  def index
    @q = Venue.ransack(params.fetch("q", nil))
    @venues = @q.result(:distinct => true).includes(:bookmarks, :neighborhood, :fans, :specialties)
    @location_hash = Gmaps4rails.build_markers(@venues.where(id: Bookmark.where(user_id: current_user.id).pluck(:venue_id))) do |venue, marker|
        @street_address = venue.address
        @url_safe_street_address = URI.encode(@street_address)
        @url="https://maps.googleapis.com/maps/api/geocode/json?address=#{@url_safe_street_address}&key=AIzaSyA5qwIlcKjijP_Ptmv46mk4cCjuWhSzS78"
        parsed_data = JSON.parse(open(@url).read)
        latitude = parsed_data.dig("results",0,"geometry","location","lat")
        longitude = parsed_data.dig("results",0,"geometry","location","lng")
        marker.lat latitude
        marker.lng longitude
          marker.infowindow "<h5><a href='/venues/#{venue.id}'>#{venue.name}</a></h5><small>#{venue.address}</small>" 
      
    end

    render("venues_templates/index.html.erb")
  end

  def show
    @bookmark = Bookmark.new
    @venue = Venue.find(params.fetch("id"))
    @street_address = @venue.address
    @url_safe_street_address = URI.encode(@street_address)
    @url="https://maps.googleapis.com/maps/api/geocode/json?address=#{@url_safe_street_address}&key=AIzaSyA5qwIlcKjijP_Ptmv46mk4cCjuWhSzS78"
    parsed_data = JSON.parse(open(@url).read)
    latitude = parsed_data.dig("results",0,"geometry","location","lat")
    longitude = parsed_data.dig("results",0,"geometry","location","lng")
    @location_hash = Gmaps4rails.build_markers(@venue) do |venue, marker|
      marker.lat latitude
      marker.lng longitude
      marker.infowindow "<h5>#{venue.created_at}</h5><small>#{venue.address}</small>"
    end
    render("venues_templates/show.html.erb")
  end

  def new
    @venue = Venue.new

    render("venues_templates/new.html.erb")
  end

  def create
    @venue = Venue.new

    @venue.name = params.fetch("name")
    @venue.address = params.fetch("address")
    @venue.neighborhood_id = params.fetch("neighborhood_id")

    save_status = @venue.save

    if save_status == true
      referer = URI(request.referer).path

      case referer
      when "/venues/new", "/create_venue"
        redirect_to("/venues")
      else
        redirect_back(:fallback_location => "/", :notice => "Venue created successfully.")
      end
    else
      render("venues_templates/new.html.erb")
    end
  end

  def edit
    @venue = Venue.find(params.fetch("id"))

    render("venues_templates/edit.html.erb")
  end

  def update
    @venue = Venue.find(params.fetch("id"))

    @venue.name = params.fetch("name")
    @venue.address = params.fetch("address")
    @venue.neighborhood_id = params.fetch("neighborhood_id")

    save_status = @venue.save

    if save_status == true
      referer = URI(request.referer).path

      case referer
      when "/venues/#{@venue.id}/edit", "/update_venue"
        redirect_to("/venues/#{@venue.id}", :notice => "Venue updated successfully.")
      else
        redirect_back(:fallback_location => "/", :notice => "Venue updated successfully.")
      end
    else
      render("venues_templates/edit.html.erb")
    end
  end

  def destroy
    @venue = Venue.find(params.fetch("id"))

    @venue.destroy

    if URI(request.referer).path == "/venues/#{@venue.id}"
      redirect_to("/", :notice => "Venue deleted.")
    else
      redirect_back(:fallback_location => "/", :notice => "Venue deleted.")
    end
  end
end
