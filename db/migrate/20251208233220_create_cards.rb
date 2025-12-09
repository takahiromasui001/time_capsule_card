class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content
      t.integer :status, null: false, default: 0
      t.datetime :scheduled_at, null: false
      t.datetime :completed_at
      t.integer :snoozed_count, default: 0
      t.integer :position

      t.timestamps
    end
  end
end
