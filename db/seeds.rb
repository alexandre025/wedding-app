families = {
  "Melchior" => [
    { first_name: "Mélanie", email: "famille.melchior@exemple.fr", attends: "true", attends_brunch: "1",
      attends_run: "1" },
    { first_name: "Sylvain", attends: "true", attends_brunch: "1", no_alcohol: "1" },
    { first_name: "Célie", age_group: FamilyMember::TEEN, attends: "true", attends_run: "1" },
    { first_name: "Léna", age_group: FamilyMember::KID, attends: "true", attends_brunch: "1" }
  ],
  "Martin" => [
    { first_name: "Camille", email: "camille.martin@exemple.fr", attends: "true", attends_brunch: "1",
      allergies: "Arachides et fruits à coque" },
    { first_name: "Julien", attends: "false" }
  ],
  "Dubois" => [
    { first_name: "Hélène", email: "helene.dubois@exemple.fr", attends: "true", attends_run: "1",
      allergies: "Sans gluten" },
    { first_name: "Marc", attends: "false", no_alcohol: "1" },
    { first_name: "Lucas", age_group: FamilyMember::BABY, attends: "true", attends_brunch: "1" }
  ],
  "Roux" => [
    { first_name: "Antoine", email: "antoine.roux@exemple.fr" }
  ]
}

families.each do |name, members|
  form = Admin::FamilyForm.new(Family.new)
  form.submit(name:)
  family = form.family

  members.each do |member_params|
    Admin::FamilyMemberForm.new(family.family_members.build).submit(member_params)
  end
end
