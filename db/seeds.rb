families = {
  "Melchior" => [
    { first_name: "Mélanie", email: "famille.melchior@exemple.fr" },
    { first_name: "Sylvain" },
    { first_name: "Célie", age_group: FamilyMember::TEEN },
    { first_name: "Léna", age_group: FamilyMember::KID }
  ],
  "Martin" => [
    { first_name: "Camille", email: "camille.martin@exemple.fr" },
    { first_name: "Julien" }
  ],
  "Dubois" => [
    { first_name: "Hélène", email: "helene.dubois@exemple.fr" },
    { first_name: "Marc" },
    { first_name: "Lucas", age_group: FamilyMember::BABY }
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
