class ActionText::Markdown::UploadsController < ApplicationController
  allow_unauthenticated_access only: :show

  before_action do
    ActiveStorage::Current.url_options = { protocol: request.protocol, host: request.host, port: request.port }
  end

  before_action :set_record, :ensure_editable, only: :create

  def create
    @markdown = @record.safe_markdown_attribute params[:attribute_name]
    @markdown.uploads.attach [ params[:file] ]
    @markdown.save!

    @upload = @markdown.uploads.attachments.last

    render :create, status: :created, formats: :json
  end

  def show
    @attachment = ActiveStorage::Attachment.find_by! slug: "#{params[:slug]}.#{params[:format]}"
    expires_in 1.year, public: true
    redirect_to @attachment.url
  end

  private
    # The signed id rendered into the page editor says who could upload when it was
    # minted, not who may upload now. Resolve the book it belongs to and authorize
    # against that, so revoking access takes effect here like it does everywhere else.
    def set_record
      @record = GlobalID::Locator.locate_signed params[:record_gid],
        only: Page, for: ActionText::Markdown::UPLOADS_SIGNED_ID_PURPOSE
      @book = Book.accessable_or_published.find_by(id: @record&.owning_book&.id)

      head :not_found unless @book
    end

    def ensure_editable
      head :forbidden unless @book.editable?
    end
end
