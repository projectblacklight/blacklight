class FolderController < ApplicationController

  include Blacklight::SolrHelper

  # fetch the documents that match the ids in the folder
  def index
    @response, @documents = get_solr_response_for_field_values("id",session[:folder_document_ids] || [])
  end

  # add a document_id to the folder
  def create
    session[:folder_document_ids] = session[:folder_document_ids] || []
    session[:folder_document_ids] << params[:id] 
    flash[:notice] = "#{params[:title] || "Item"} successfully added to Folder"
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render :json => session[:folder_document_ids] }
    end
  end
 
  # remove a document_id from the folder
  def destroy
    session[:folder_document_ids].delete(params[:id])
    flash[:notice] = "#{params[:title] || "Item"} successfully removed from Folder"
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render :json => session[:folder_document_ids] }
    end
  end
 
  # get rid of the items in the folder
  def clear
    flash[:notice] = "Cleared Folder"
    session[:folder_document_ids] = []
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render :json => session[:folder_document_ids] }
    end
  end
 
end
