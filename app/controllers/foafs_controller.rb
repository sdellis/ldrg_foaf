require 'rdf'
require 'linkeddata'
require 'json'
# require 'json/ld'

class FoafsController < ApplicationController
  before_action :set_foaf, only: [:show, :edit, :update, :destroy]

  # GET /foafs
  # GET /foafs.json
  def index
    @foafs = Foaf.all
    # if all else fails, make RDF then
    # rapper -o dot -i turtle me.ttl | dot -Tsvg -o me.svg
    respond_to do |format|
      format.html #{ render text: convert_one_to_rdf(@foaf, :html) }
      format.ttl { render text: convert_many_to_rdf(@foafs, :ttl) }
      format.rj { render text: convert_many_to_rdf(@foafs, :json) }
      format.nt { render text: convert_many_to_rdf(@foafs, :ntriples) }
      format.rdf { render text: convert_many_to_rdf(@foafs, :rdf) }
      format.jsonld { render text: convert_many_to_rdf(@foafs, :jsonld) }
    end
  end

  # GET /foafs/1
  # GET /foafs/1.json
  def show
      # @foaf = Foaf.find(:id)
    respond_to do |format|
      format.html { render layout: false }#text: convert_one_to_rdf(@foaf, :html) }
      format.ttl { render text: convert_one_to_rdf(@foaf, :ttl) }
      format.rj { render text: convert_one_to_rdf(@foaf, :json) }
      format.nt { render text: convert_one_to_rdf(@foaf, :ntriples) }
      format.rdf { render text: convert_one_to_rdf(@foaf, :rdf) }
      format.jsonld { render text: convert_one_to_rdf(@foaf, :jsonld) }
    end
  end

  def uri
    uri = "http://#{request.host}#{request.fullpath}"
  end

  def convert_one_to_rdf(foaf, fmt) 
    output = foaf.to_doc_graph(uri).dump(fmt, prefixes: Foaf::PREFIXES)
    if [:json, :jsonld].include? fmt # make it easier to read
      JSON.pretty_generate(JSON.parse!(output))
    end
    output
  end

  def convert_many_to_rdf(foafs, fmt) 
    graph = RDF::Graph.new
    foafs.each do |f|
      current_uri = RDF::URI.new("http://#{request.host}#{request.fullpath}")
      path = Foaf.strip_extension_from_uri(current_uri)
      uri = "#{path}/#{f.slug}#me"
      graph << f.to_graph(uri)
    end
    output = graph.dump(fmt, prefixes: Foaf::PREFIXES)
    if [:json, :jsonld].include? fmt # make it easier to read
      JSON.pretty_generate(JSON.parse!(output))
    end
    output
  end

  # GET /foafs/new
  def new
    @foaf = Foaf.new
    # 2.times { @foaf.interests.build }
    1.times { @foaf.interests.build }
  end

  # GET /foafs/1/edit
  def edit
    1.times { @foaf.interests.build }
  end

  # POST /foafs
  # POST /foafs.json
  def create

    # Rails.logger.warn "===================="
    # Rails.logger.warn foaf_params[:interests_attributes]
    # Rails.logger.warn "===================="

    
    @foaf = Foaf.new(name: foaf_params[:name], work: foaf_params[:work], 
      slug: foaf_params[:slug], birthday: foaf_params[:birthday])

    if(foaf_params.has_key?(:interests_attributes))
      interest_ids = foaf_params[:interests_attributes].split(",").map { |s| s.to_i }
      interest_ids.each do |i|
        @foaf.interests << Interest.find(i)
      end
    end

    respond_to do |format|
      if @foaf.save 
        format.html { redirect_to @foaf, notice: 'Foaf was successfully created.' }
        format.json { render action: 'show', status: :created, location: @foaf }
      else
        format.html { render action: 'new' }
        format.json { render json: @foaf.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /foafs/1
  # PATCH/PUT /foafs/1.json
  def update

    @foaf.interests.clear

    if(foaf_params.has_key?(:interests_attributes))
      interest_ids = foaf_params[:interests_attributes].split(",").map { |s| s.to_i }
      interest_ids.each do |i|
        @foaf.interests << Interest.find(i)
        #@foaf.update(Interest.find(i))
      end
      
    end

    respond_to do |format|
      if @foaf.update(name: foaf_params[:name], work: foaf_params[:work], 
      slug: foaf_params[:slug], birthday: foaf_params[:birthday])
        format.html { redirect_to @foaf, notice: 'Foaf was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @foaf.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /foafs/1
  # DELETE /foafs/1.json
  def destroy
    @foaf.destroy

    respond_to do |format|
      format.html { redirect_to foafs_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_foaf
      @foaf = Foaf.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def foaf_params
      params.require(:foaf).permit(:name, :work, :slug, :birthday, :interests_attributes)
    end
end
