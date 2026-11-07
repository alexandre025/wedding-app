class AddSongToFamilies < ActiveRecord::Migration[8.1]
  def change
    add_column :families, :song, :string
  end
end
