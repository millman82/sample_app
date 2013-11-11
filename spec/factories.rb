FactoryGirl.define do
  factory :user do
    name                   "Timothy Miller"
    email                  "tmiller@example.com"
    password               "foobar"
    password_confirmation  "foobar"
  end
end