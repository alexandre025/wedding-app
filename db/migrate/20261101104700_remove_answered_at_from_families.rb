class RemoveAnsweredAtFromFamilies < ActiveRecord::Migration[8.1]
  def change
    remove_column :families, :answered_at, :datetime
  end
end
