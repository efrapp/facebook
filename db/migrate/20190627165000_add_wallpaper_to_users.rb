class AddWallpaperToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :wallpaper, :string
  end
end
