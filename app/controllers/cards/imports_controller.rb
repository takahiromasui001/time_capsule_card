class Cards::ImportsController < ApplicationController
  def create
    importer = CardCsvImporter.new(current_user, params[:file])

    if importer.import
      redirect_to cards_scheduled_index_path, notice: 'インポートが完了しました'
    else
      @errors = importer.errors
      render turbo_stream: turbo_stream.replace(
        'import_form_modal',
        partial: 'cards/imports/form',
        locals: { errors: @errors }
      ), status: :unprocessable_entity
    end
  end
end
