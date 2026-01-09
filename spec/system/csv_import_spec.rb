require 'rails_helper'

RSpec.describe 'CSV Import', type: :system do
  include_context 'ログイン済みユーザー'

  describe 'CSVインポート' do
    it 'CSVファイルをインポートできる' do
      visit cards_scheduled_index_path
      find('[data-action="click->dropdown#toggle"]').click
      click_button 'CSVインポート'

      expect(page).to have_css('#import_form_modal', visible: true)

      csv_content = "title,content,scheduled_at,status\nテストカード,テスト内容,2026-01-10,scheduled"
      file = Tempfile.new(['test_cards', '.csv'])
      file.write(csv_content)
      file.rewind

      attach_file 'file', file.path

      click_button 'インポート'

      expect(page).to have_content('インポートが完了しました')
      expect(page).to have_css('#import_form_modal.hidden')

      file.close
      file.unlink
    end
  end
end
