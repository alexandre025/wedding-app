class CreateFamiliesAndFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :families do |t|
      t.string :name, null: false
      t.datetime :answered_at

      t.timestamps
    end

    create_table :family_members do |t|
      t.references :family, null: false
      t.string :first_name, null: false
      t.string :email

      t.timestamps
    end

    add_index :family_members, :email, unique: true
  end
end
