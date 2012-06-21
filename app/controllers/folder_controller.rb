# -*- encoding : utf-8 -*-
class FolderController < ApplicationController
  include Blacklight::Configurable
  include Blacklight::SolrHelper

  copy_blacklight_config_from(CatalogController)

  helper CatalogHelper

  # fetch the documents that match the ids in the folder
  def index
    @response, @documents = get_solr_response_for_field_values("id",session[:folder_document_ids] || [])
  end
    

  # add a document_id to the folder. :id of action is solr doc id 
  def update
    session[:folder_document_ids] = session[:folder_document_ids] || []
    session[:folder_document_ids] << params[:id] 
    # Rails 3 uses a one line notation for setting the flash notice.
    #    flash[:notice] = "#{params[:title] || "Item"} successfully added to Folder"
    respond_to do |format|
      format.html { redirect_to :back, :notice =>  I18n.t('blacklight.folder.add.success', :title => params[:title] || 'Item') }
      format.js { render :json => session[:folder_document_ids] }
    end
  end
 
  # remove a document_id from the folder. :id of action is solr_doc_id
  def destroy
    session[:folder_document_ids].delete(params[:id])
          
    respond_to do |format|
      format.html do
        flash[:notice] = I18n.t('blacklight.folder.remove.success', :title => params[:title] || 'Item')
        redirect_to :back
      end
      format.js do
        render :json => {"OK" => "OK"}
      end
    end
          
  end
 
  # get rid of the items in the folder
  def clear
    flash[:notice] = I18n.t('blacklight.folder.clear.success')
    session[:folder_document_ids] = []
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render :json => session[:folder_document_ids] }
    end
  end
 
end
