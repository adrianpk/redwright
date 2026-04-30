class AddRolesJsonToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :roles_json, :text, null: false, default: "[]"
  end
end

