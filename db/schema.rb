ActiveRecord::Schema.define(version: 20170503135542) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.integer "visits"
  end
end
