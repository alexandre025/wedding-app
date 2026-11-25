class Rsvp::LinksController < ApplicationController
  def new
    return redirect_to rsvp_answer_path(cookies.signed[:rsvp_token]) if remembered_family?

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

  def destroy
    cookies.delete(:rsvp_token)
    redirect_to rsvp_path
  end

  private
    def remembered_family?
      return true if Family.find_signed(cookies.signed[:rsvp_token], purpose: :rsvp)

      cookies.delete(:rsvp_token)
      false
    end

    def link_request_params
      params.require(:link_request)
    end
end
