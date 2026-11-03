class AddVegetarianToFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :family_members, :vegetarian, :boolean, null: false, default: false
  end
end
