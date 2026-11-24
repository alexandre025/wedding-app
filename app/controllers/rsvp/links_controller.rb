class Rsvp::LinksController < ApplicationController
  def new
    @form = Rsvp::LinkRequestForm.new
  end

  def create
    @form = Rsvp::LinkRequestForm.new

    if @form.submit(link_request_params)
      redirect_to rsvp_path, flash: { link_sent_to: @form.email }
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def link_request_params
      params.require(:link_request)
    end
end
