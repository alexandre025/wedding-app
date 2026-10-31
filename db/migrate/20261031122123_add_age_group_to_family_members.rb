class AddAgeGroupToFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :family_members, :age_group, :string, null: false, default: FamilyMember::ADULT
  end
end
