class Rsvp::AnswersController < ApplicationController
  before_action :set_family

  rescue_from ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound, with: :reject_link

  def show
    return redirect_to edit_rsvp_answer_path(params[:token]) unless @family.answered?

    @answer = Rsvp::AnswerPresenter.new(@family)
  end

  def edit
    @form = Rsvp::AnswerForm.new(@family)
  end

  def update
    @form = Rsvp::AnswerForm.new(@family)

    if @form.submit(answer_params)
      redirect_to rsvp_answer_path(params[:token])
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_family
      @family = Family.includes(:family_members).find_signed!(params[:token], purpose: :rsvp)
    end

    def reject_link
      redirect_to rsvp_path, alert: t("rsvp.answers.invalid_link")
    end

    def answer_params
      params.require(:answer)
    end
end
