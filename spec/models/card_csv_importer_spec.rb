require 'rails_helper'

RSpec.describe CardCsvImporter do
  let(:user) { create(:user) }
  let(:file) { create_temp_csv(csv_content) }
  let(:importer) { described_class.new(user, file) }

  subject { importer.import }

  describe '#import' do
    context '正常系' do
      let(:csv_content) do
        <<~CSV
          title,content,scheduled_at,status
          Test Card,Test Content,2025-01-01 10:00:00,scheduled
        CSV
      end

      it 'CSVファイルからカードをインポートできる' do
        expect { subject }.to change { user.cards.count }.by(1)

        card = user.cards.last
        expect(card.title).to eq('Test Card')
        expect(card.content).to eq('Test Content')
        expect(card.status).to eq('scheduled')
      end

      context 'statusが数値の場合' do
        let(:csv_content) do
          <<~CSV
            title,content,scheduled_at,status
            Card 1,Content,2025-01-01 10:00:00,0
            Card 2,Content,2025-01-01 10:00:00,10
          CSV
        end

        it 'インポートできる' do
          subject

          expect(user.cards.find_by(title: 'Card 1').status).to eq('scheduled')
          expect(user.cards.find_by(title: 'Card 2').status).to eq('arrived')
        end
      end
    end

    context '異常系' do
      context 'ファイルが選択されていない場合' do
        let(:file) { nil }
        let(:csv_content) { '' }

        it 'エラーを返す' do
          expect(subject).to be false
          expect(importer.errors).to include('ファイルを選択してください')
        end
      end

      context 'バリデーションエラーがある場合' do
        let(:csv_content) do
          <<~CSV
            title,content,scheduled_at,status
            Valid Card,Content,2025-01-01 10:00:00,scheduled
            ,Invalid Card,,scheduled
          CSV
        end

        it '全件ロールバックする' do
          expect { subject }.not_to change { user.cards.count }
          expect(importer.errors).to be_present
        end
      end
    end
  end

  private

  def create_temp_csv(content)
    file = Tempfile.new(['test', '.csv'])
    file.write(content)
    file.rewind
    file
  end
end
