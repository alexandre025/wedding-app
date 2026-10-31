FAMILIES = {
  "Melchior" => [
    { first_name: "Mélanie", email: "famille.melchior@exemple.fr" },
    { first_name: "Sylvain" },
    { first_name: "Célie", age_group: "teen" },
    { first_name: "Léna", age_group: "kid" }
  ],
  "Martin" => [
    { first_name: "Camille", email: "camille.martin@exemple.fr" },
    { first_name: "Julien" }
  ],
  "Dubois" => [
    { first_name: "Hélène", email: "helene.dubois@exemple.fr" },
    { first_name: "Marc" },
    { first_name: "Lucas", age_group: "baby" }
  ],
  "Roux" => [
    { first_name: "Antoine", email: "antoine.roux@exemple.fr" }
  ]
}

FAMILIES.each do |name, members|
  family = Family.find_or_create_by!(name:)

  members.each do |attributes|
    member = family.family_members.find_or_initialize_by(first_name: attributes[:first_name])
    member.update!(email: attributes[:email], age_group: attributes.fetch(:age_group, "adult"))
  end
end
