class AddOptionsToFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :family_members, :attends, :boolean
    add_column :family_members, :no_alcohol, :boolean, null: false, default: false
    add_column :family_members, :attends_brunch, :boolean, null: false, default: false
    add_column :family_members, :attends_run, :boolean, null: false, default: false
    add_column :family_members, :allergies, :text

    reversible do |dir|
      dir.up { execute "UPDATE family_members SET no_alcohol = true WHERE age_group <> 'adult'" }
    end
  end
end
