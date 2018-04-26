class CreateConfirmationCodes < ActiveRecord::Migration[5.1]
  def change
    create_table :confirmation_codes do |t|
      t.references :player, foreign_key: true
      t.string :code
      t.string :method
      t.timestamps
    end
  end
end
